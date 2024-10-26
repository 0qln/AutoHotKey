use std::marker::PhantomData;

use once_cell::sync::OnceCell;

use windows::Win32::{
    Foundation::{HWND, POINT, RECT},
    UI::WindowsAndMessaging::{
        GetWindowLongPtrW, GetWindowRect, MoveWindow, ShowWindow, WindowFromPoint,
        SHOW_WINDOW_CMD, WINDOW_LONG_PTR_INDEX,
    },
};


pub mod state {
    pub struct Restored;
    pub struct Minimized;
    pub struct Maximized;
    pub struct Unknown;
}

#[derive(Debug, Default)]
pub struct WindowModel {
    handle: HWND,
    rect: OnceCell<RECT>,
    visibility: OnceCell<i8>,
    style: OnceCell<isize>,
}

impl WindowModel {
    pub fn new(handle: HWND) -> Self {
        Self {
            handle,
            ..Default::default()
        }
    }

    pub fn get_handle(&self) -> HWND {
        self.handle
    }

    pub unsafe fn get_rect(&'_ self) -> &'_ RECT {
        &self.rect.get_or_init(|| {
            let mut rect = RECT::default();
            let _ = GetWindowRect(self.handle, &mut rect);
            rect
        })
    }

    pub unsafe fn get_visibility(&self) -> i8 {
        *self.visibility.get_or_init(|| {
            let corner_radius = 20;
            let l = self.get_rect().left + corner_radius;
            let t = self.get_rect().top + corner_radius;
            let r = self.get_rect().right - corner_radius;
            let b = self.get_rect().bottom - corner_radius;
            let w = r - l;
            let h = b - t;
            unsafe fn score_point(this: &WindowModel, x: i32, y: i32) -> i8 {
                if this.handle == WindowFromPoint(POINT { x, y }) { 1 } else { 0 }
            }
            score_point(self, l, t) + score_point(self, r, t) +
            score_point(self, l, b) + score_point(self, r, b) +
            score_point(self, l + w / 2, t + h / 2)
        })
    }

    pub unsafe fn get_style(&self) -> isize {
        *self.style.get_or_init(|| {
            GetWindowLongPtrW(self.handle, WINDOW_LONG_PTR_INDEX(-16))               
        })
    }

    pub unsafe fn is_maximized(&self) -> bool {
        self.get_style() & 0x01000000 != 0
    }

    pub unsafe fn is_minimized(&self) -> bool {
        self.get_style() & 0x20000000 != 0
    }

    pub unsafe fn is_restored(&self) -> bool {
        !self.is_maximized() && !self.is_minimized()
    }
}

#[derive(Debug)]
pub struct Window<'a, State> {
    info: &'a WindowModel,
    state: PhantomData<State>,
}

impl<'a, State> Window<'a, State> {
    pub fn new(info: &'a WindowModel) -> Self {
        Self {
            info: info,
            state: PhantomData,
        }
    }

    pub fn get_handle(&self) -> HWND {
        self.info.get_handle()
    }

    pub unsafe fn get_rect(&'_ self) -> &'_ RECT {
        self.info.get_rect()
    }

    pub unsafe fn get_visibility(&'_ mut self) -> i8 {
        self.info.get_visibility()
    }

    pub unsafe fn get_style(&self) -> isize {
        self.info.get_style()
    }

    pub unsafe fn is_maximized(&self) -> bool {
        self.info.is_maximized()
    }

    pub unsafe fn is_minimized(&self) -> bool {
        self.info.is_minimized()
    }

    pub unsafe fn is_restored(&self) -> bool {
        self.info.is_restored()
    }

    pub unsafe fn restore(self) -> Window<'a, state::Restored> {
        let _ = ShowWindow(self.info.handle, SHOW_WINDOW_CMD(9));
        Window::<state::Restored>::new(self.info)
    }

    pub unsafe fn maximize(self) -> Window<'a, state::Maximized> {
        let _ = ShowWindow(self.info.handle, SHOW_WINDOW_CMD(3));
        Window::<state::Maximized>::new(self.info)
    }

    pub unsafe fn minimize(self) -> Window<'a, state::Minimized> {
        let _ = ShowWindow(self.info.handle, SHOW_WINDOW_CMD(6));
        Window::<state::Minimized>::new(self.info)
    }
}

impl<'a> Window<'a, state::Maximized> {
    /// Moves the window from one monitor to another
    pub unsafe fn move_screen(
        self,
        old_monitor: RECT,
        new_monitor: RECT,
    ) -> windows::core::Result<Window<'a, state::Maximized>> {
        let restored_window = Window::<'a, state::Maximized>::restore(self);
        restored_window.move_screen(old_monitor, new_monitor)?;
        Ok(restored_window.maximize())
    }
}

impl<'a> Window<'a, state::Restored> {
    /// Moves the window from one monitor to another
    pub unsafe fn move_screen(
        &self,
        old_monitor: RECT,
        new_monitor: RECT,
    ) -> windows::core::Result<()> {
        let rect = self.get_rect();
        let old_mon_w = old_monitor.right - old_monitor.left;
        let old_mon_h = old_monitor.bottom - old_monitor.top;
        let old_aspect_ratio = old_mon_w as f32 / old_mon_h as f32;
        let old_rel_x = rect.left - old_monitor.left;
        let old_rel_y = rect.top - old_monitor.top;
        let old_mon_norm_x = old_rel_x as f32 / old_mon_w as f32;
        let old_mon_norm_y = old_rel_y as f32 / old_mon_h as f32;
        let old_w = rect.right - rect.left;
        let old_h = rect.bottom - rect.top;
        let old_scale_x = old_w as f32 / old_mon_w as f32;
        let old_scale_y = old_h as f32 / old_mon_h as f32;

        let new_mon_w = new_monitor.right - new_monitor.left;
        let new_mon_h = new_monitor.bottom - new_monitor.top;
        let new_aspect_ratio = new_mon_w as f32 / new_mon_h as f32;

        // The default:
        // scale the window such that it fits the new monitor size,
        // and keeps it's aspect ratio
        let mut new_rel_x = old_mon_norm_x * new_mon_w as f32;
        let mut new_rel_y = old_mon_norm_y * new_mon_h as f32;
        let mut new_w = old_scale_x * new_mon_w as f32;
        let mut new_h = old_scale_y * new_mon_h as f32;

        // Smart swap:
        // If the new monitor has a wastly different aspect ratio,
        // hinting at a different monitor orientations:
        if (old_aspect_ratio < 1.0 && new_aspect_ratio > 1.0) || 
            (old_aspect_ratio > 1.0 && new_aspect_ratio < 1.0)
        {
            // scale the window to a fitting size
            new_rel_x = old_mon_norm_y * new_mon_w as f32;
            new_rel_y = old_mon_norm_x * new_mon_h as f32;
            new_w = old_scale_y * new_mon_w as f32;
            new_h = old_scale_x * new_mon_h as f32;
        }

        let new_abs_x = new_monitor.left + new_rel_x as i32;
        let new_abs_y = new_monitor.top + new_rel_y as i32;

        MoveWindow(
            self.get_handle(),
            new_abs_x,
            new_abs_y,
            new_w as i32,
            new_h as i32,
            true,
        )
    }
}
