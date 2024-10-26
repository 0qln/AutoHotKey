use std::{cmp::min, rc::Rc};
use once_cell::sync::OnceCell;

use windows::Win32::{
    Foundation::{BOOL, LPARAM, RECT},
    Graphics::Gdi::{EnumDisplayMonitors, MonitorFromWindow, HDC, HMONITOR, MONITOR_FROM_FLAGS},
};

use crate::{misc::Direction, window::WindowModel};

struct GetMonitorRectInfo {
    monitor_to_find: HMONITOR,
    result: Option<RECT>,
}

#[derive(Debug, Default)]
pub struct Monitor {
    handle: HMONITOR,
    rect: OnceCell<RECT>,
    left: OnceCell<Option<Rc<Monitor>>>,
    right: OnceCell<Option<Rc<Monitor>>>,
    up : OnceCell<Option<Rc<Monitor>>>,
    down: OnceCell<Option<Rc<Monitor>>>,
}

impl From<&WindowModel> for Monitor {
    fn from(win: &WindowModel) -> Self {
        unsafe {
            Self::new(MonitorFromWindow(win.get_handle(), MONITOR_FROM_FLAGS(2)))
        }
    }
}

impl Monitor {
    pub fn new(handle: HMONITOR) -> Self {
        Self { handle, ..Default::default() }
    }

    pub fn get_handle(&self) -> HMONITOR {
        self.handle
    }
    
    pub unsafe fn get_rect(&self) -> &RECT {
        self.rect.get_or_init(|| {
            let mut info = GetMonitorRectInfo {
                monitor_to_find: self.get_handle(),
                result: None,
            };
            let _ = EnumDisplayMonitors(
                HDC::default(),
                None,
                Some(enum_proc),
                LPARAM(&mut info as *mut GetMonitorRectInfo as isize),
            );

            unsafe extern "system" fn enum_proc(
                param0: HMONITOR,
                _param1: HDC,
                param2: *mut RECT,
                param3: LPARAM,
            ) -> BOOL {
                let info = param3.0 as *mut GetMonitorRectInfo;
                if let Some(info) = info.as_mut() {
                    if param0 == info.monitor_to_find {
                        info.result = Some(*param2);
                        return BOOL::from(false);
                    }
                }
                BOOL::from(true)
            }

            info.result.unwrap()
        })
    }
    
    pub unsafe fn get_left(&self) -> &Option<Rc<Monitor>> {
        self.left.get_or_init(|| {
            let mut info = GetMonitorInDirInfo {
                target: self,
                result: None,
            };
            
            // todo: optimize by setting the rect of the monitor we are looking for
            let _ = EnumDisplayMonitors(
                HDC::default(),
                None,
                Some(get_monitor_left_enum_proc),
                LPARAM(&mut info as *mut GetMonitorInDirInfo as isize),
            );

            unsafe extern "system" fn get_monitor_left_enum_proc(
                param0: HMONITOR,
                _param1: HDC,
                param2: *mut RECT,
                param3: LPARAM,
            ) -> BOOL {
                let info = param3.0 as *mut GetMonitorInDirInfo;
                let mut r#break = false;
                if let Some(info) = info.as_mut() {
                    let mon = *param2;
                    let target = info.target;
                    if mon.right == target.get_rect().left {
                        // If this is the first adjacent monitor, replace.
                        let mut replace = info.result.is_none();

                        // Or if the new monitor is closer vertically, replace.
                        if let Some(old_result) = &info.result {
                            let target_top = target.get_rect().top;
                            let target_bottom = target.get_rect().bottom;
                            let target_height = target_bottom - target_top;
                            let target_middle = target_top + target_height / 2;

                            let old_top = old_result.get_rect().top;
                            let old_bot = old_result.get_rect().bottom;
                            let old_score = min((target_middle - old_top).abs(), (target_middle - old_bot).abs());

                            let new_top = mon.top;
                            let new_bot = mon.bottom;
                            let new_score = min((target_middle - new_top).abs(), (target_middle - new_bot).abs());
                            
                            // If the target's mid point is between the new monitor's top and bottom
                            // we have found the closest monitor.
                            if new_top < target_middle && new_bot > target_middle {
                                r#break = true;                                    
                            }

                            replace = new_score < old_score;
                        }

                        if replace {
                            info.result = Some(Monitor {
                                handle: param0,
                                rect: OnceCell::with_value(mon),
                                // Don't create a backlink to the target. The target
                                // might not be the closest monitor for the result.
                                // right: info.target,
                                ..Default::default()
                            });
                        }
                    }
                }

                return BOOL::from(!r#break);
            }
            
            info.result.map(Rc::new)
        })
    }
    
    pub unsafe fn get_up(&self) -> &Option<Rc<Monitor>> {
        self.up.get_or_init(|| {
            let mut info = GetMonitorInDirInfo {
                target: self,
                result: None,
            };

            // todo: optimize by setting the rect of the monitor we are looking for
            let _ = EnumDisplayMonitors(
                HDC::default(),
                None,
                Some(get_monitor_up_enum_proc),
                LPARAM(&mut info as *mut GetMonitorInDirInfo as isize),
            );

            unsafe extern "system" fn get_monitor_up_enum_proc(
                param0: HMONITOR,
                _param1: HDC,
                param2: *mut RECT,
                param3: LPARAM,
            ) -> BOOL {
                let info = param3.0 as *mut GetMonitorInDirInfo;
                let mut r#break = false;
                if let Some(info) = info.as_mut() {
                    let mon = *param2;
                    let target = info.target;
                    if mon.bottom == info.target.get_rect().top {
                        // If this is the first adjacent monitor, replace.
                        let mut replace = info.result.is_none();

                        // Or if the new monitor is closer horizontally, replace.
                        if let Some(old_result) = &info.result {
                            let target_left = target.get_rect().left;
                            let target_right = target.get_rect().right;
                            let target_width = target_right - target_left;
                            let target_middle = target_left + target_width / 2;

                            let old_left = old_result.get_rect().left;
                            let old_right = old_result.get_rect().right;
                            let old_score = min((target_middle - old_left).abs(), (target_middle - old_right).abs());

                            let new_left = mon.left;
                            let new_right = mon.right;
                            let new_score = min((target_middle - new_left).abs(), (target_middle - new_right).abs());
                            
                            // If the target's mid point is between the new monitor's left and right
                            // we have found the closest monitor.
                            if new_left < target_middle && new_right > target_middle {
                                r#break = true;                                    
                            }

                            replace = new_score < old_score;
                        }

                        if replace {
                            info.result = Some(Monitor {
                                handle: param0,
                                rect: OnceCell::with_value(mon),
                                // Don't create a backlink to the target. The target
                                // might not be the closest monitor for the result.
                                // down: info.target,
                                ..Default::default()
                            });
                        }
                    }
                }
                
                BOOL::from(!r#break)
            }
            
            info.result.map(Rc::new)
        })
    }
    
    pub unsafe fn get_right(&self) -> &Option<Rc<Monitor>> {
        self.right.get_or_init(|| {
            let mut info = GetMonitorInDirInfo {
                target: self,
                result: None,
            };
            let _ = EnumDisplayMonitors(
                HDC::default(),
                None,
                Some(get_monitor_right_enum_proc),
                LPARAM(&mut info as *mut GetMonitorInDirInfo as isize),
            );
            
            unsafe extern "system" fn get_monitor_right_enum_proc(
                param0: HMONITOR,
                _param1: HDC,
                param2: *mut RECT,
                param3: LPARAM,
            ) -> BOOL {
                let info = param3.0 as *mut GetMonitorInDirInfo;
                let mut r#break = false;
                if let Some(info) = info.as_mut() {
                    let mon = *param2;
                    let target = info.target;
                    if mon.left == info.target.get_rect().right {
                        // If this is the first adjacent monitor, replace.
                        let mut replace = info.result.is_none();

                        // Or if the new monitor is closer vertically, replace.
                        if let Some(old_result) = &info.result {
                            let target_top = target.get_rect().top;
                            let target_bot = target.get_rect().bottom;
                            let target_height = target_bot - target_top;
                            let target_middle = target_top + target_height / 2;

                            let old_top = old_result.get_rect().top;
                            let old_bot = old_result.get_rect().bottom;
                            let old_score = min((target_middle - old_top).abs(), (target_middle - old_bot).abs());

                            let new_top = mon.top;
                            let new_bot = mon.bottom;
                            let new_score = min((target_middle - new_top).abs(), (target_middle - new_bot).abs());
                            
                            // If the target's mid point is between the new monitor's top and bottom
                            // we have found the closest monitor.
                            if new_top < target_middle && new_bot > target_middle {
                                r#break = true;
                            }

                            replace = new_score < old_score;
                        }
        
                        if replace {
                            info.result = Some(Monitor {
                                handle: param0,
                                rect: OnceCell::with_value(mon),
                                // Don't create a backlink to the target. The target
                                // might not be the closest monitor for the result.
                                // left: info.target,
                                ..Default::default()
                            });
                        }
                    }
                }
                
                BOOL::from(!r#break)
            }

            info.result.map(Rc::new)
        })
    }
    
    pub unsafe fn get_down(&self) -> &Option<Rc<Monitor>> {
        self.down.get_or_init(|| {
            let mut info = GetMonitorInDirInfo {
                target: self,
                result: None,
            };
            let _ = EnumDisplayMonitors(
                HDC::default(),
                None,
                Some(get_monitor_down_enum_proc),
                LPARAM(&mut info as *mut GetMonitorInDirInfo as isize),
            );
            
            unsafe extern "system" fn get_monitor_down_enum_proc(
                param0: HMONITOR,
                _param1: HDC,
                param2: *mut RECT,
                param3: LPARAM,
            ) -> BOOL {
                let info = param3.0 as *mut GetMonitorInDirInfo;
                let mut r#break = false;
                if let Some(info) = info.as_mut() {
                    let mon = *param2;
                    let target = info.target;
                    if mon.top == info.target.get_rect().bottom {
                        // If this is the first adjacent monitor, replace.
                        let mut replace = info.result.is_none();
                        
                        // Or if the new monitor is closer vertically, replace.
                        if let Some(old_result) = &info.result {
                            let target_top = target.get_rect().top;
                            let target_bot = target.get_rect().bottom;
                            let target_height = target_bot - target_top;
                            let target_middle = target_top + target_height / 2;

                            let old_top = old_result.get_rect().top;
                            let old_bot = old_result.get_rect().bottom;
                            let old_score = min((target_middle - old_top).abs(), (target_middle - old_bot).abs());

                            let new_top = mon.top;
                            let new_bot = mon.bottom;
                            let new_score = min((target_middle - new_top).abs(), (target_middle - new_bot).abs());
                            
                            // If the target's mid point is between the new monitor's top and bottom
                            // we have found the closest monitor.
                            if new_top < target_middle && new_bot > target_middle {
                                r#break = true;
                            }

                            replace = new_score < old_score;
                        }

                        if replace {
                            info.result = Some(Monitor {
                                handle: param0,
                                rect: OnceCell::with_value(mon),
                                // Don't create a backlink to the target. The target
                                // might not be the closest monitor for the result.
                                // up: info.target,
                                ..Default::default()
                            });
                        }
                    }
                }
                
                BOOL::from(!r#break)
            }

            info.result.map(Rc::new)
        })
    }
    
    pub unsafe fn get_next_in_dir(&self, dir: Direction) -> &Option<Rc<Monitor>> {
        match dir {
            Direction::Up => self.get_up(),
            Direction::Down => self.get_down(),
            Direction::Left => self.get_left(),
            Direction::Right => self.get_right(),
        }
    }
}

struct GetMonitorInDirInfo<'a> {
    target: &'a Monitor,
    result: Option<Monitor>,
}
