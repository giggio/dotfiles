import re
from datetime import datetime
from kitty.boss import get_boss
from kitty.fast_data_types import Screen, get_options
from kitty.utils import color_as_int
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_title,
)
"""
ABOUT

Custom Kitty tab bar with three sections:
  - Left status
  - Tab Bar (with overflow indicators)
  - Right status

Left status:
  - Kitty emoji (😺)
  - Powerline separator

Tab Bar:
  - Individual tabs with:
    - Tab number
    - Title (rewritten to icons: 🏠 for home, 🗑️ for /tmp, ⚡ for ssh)
    - Window count (⊞ N) if multiple windows
    - Powerline separators
  - Overflow handling:
    - » (right) indicator when tabs are hidden after visible range
    - Smart overflow: active tab always visible, other tabs hidden when space runs out
  - Dynamic width calculation: adjusts tab width based on terminal size and tab count
"""
opts = get_options()

# Use background color as tab_background color if none is set by the theme
if opts.tab_bar_background is None:
    opts.tab_bar_background = opts.background
    # don't trust themes
    # opts.tab_bar_background = Color(0, 0, 0)
    # opts.tab_bar_background = Color(237, 28, 36) # red
    # opts.tab_bar_background = Color(229, 192, 123) # yellowish


config = {"tab_width": 25, "rewrite_title": True}
colors = {
    "fg": as_rgb(color_as_int(opts.inactive_tab_foreground)),
    "bg": as_rgb(color_as_int(opts.inactive_tab_background)),
    "active_fg": as_rgb(color_as_int(opts.active_tab_foreground)),
    "active_bg": as_rgb(color_as_int(opts.active_tab_background)),
    "bar_bg": as_rgb(color_as_int(opts.tab_bar_background)),
    "accent": as_rgb(color_as_int(opts.selection_background)),
    "background": as_rgb(color_as_int(opts.background)),
}
symbols = {"separator_right": "", "separator_left": "", "truncation": "»", "overflow_left": "«", "overflow_right": "»"}
icons = {
    "kitty": "😺",
    "window": " ⊞",  # alt: 🪟
    "tab": "📑",
    "host": "🖥️",
    "user": "👨",
    "home": "🏠",
    "root": "🌳",
    "trash": "🗑️",
    "ssh": "⚡",
    "git": "",
    "clock": "🕐",
}

_overflow_state = {
    "total_tabs": 0,
    "active_tab": 1,
    "visible_start": 1,
    "visible_end": 0,
    "right_width": 0,
    "tab_area_start": 0,
    "tab_area_end": 0,
    "overflow_triggered": False,
    "tab_width": 0,
    "num_tabs": 1
}


def _draw_window_count(screen: Screen, num_window_groups: int) -> bool:
    if num_window_groups > 1:
        screen.draw(icons["window"] + str(num_window_groups))
    return True


def _draw_left(screen: Screen) -> int:
    screen.cursor.bg = colors["bg"]
    screen.draw(icons["kitty"])
    screen.cursor.x = len(icons["kitty"]) + 1

    screen.cursor.fg = colors["bg"]
    screen.cursor.bg = colors["bar_bg"]
    screen.draw(symbols["separator_right"] + " ")

    return screen.cursor.x


def _calculate_tab_width(screen: Screen, num_tabs: int) -> int:
    left_width = 25
    right_width = 38
    available_width = screen.columns - left_width - right_width

    if num_tabs > 0:
        dynamic_width = available_width // num_tabs
        min_width = 15
        max_width = config["tab_width"]
        return max(min_width, min(max_width, dynamic_width))

    return config["tab_width"]


def _truncate_path(path: str, max_length: int) -> str:
    """Truncate a path to max_length, keeping the emoji and showing the last part."""
    if len(path) <= max_length:
        return path

    # Extract emoji and path
    if path.startswith(icons["home"]):
        emoji = icons["home"]
        remaining_path = path[len(emoji):]
    else:
        emoji = ""
        remaining_path = path

    # Calculate available space for the path content
    available = max_length - len(emoji) - 2  # -2 for the ".."

    if available < 1:
        # Not enough space, just return emoji with first char of path
        return emoji + ".." if emoji else ".."

    # Get the last parts of the path that fit
    path_parts = remaining_path.split("/")
    truncated = ""

    # Work backwards from the last part
    for part in reversed(path_parts):
        if not part:  # Skip empty parts
            continue
        needed = len(part)
        if len(truncated) == 0:
            # First (last) part
            if needed <= available:
                truncated = part
            else:
                # Even the last part is too long, truncate it
                truncated = part[:available]
                break
        else:
            # Add previous parts with /
            needed += 1  # for the /
            if len(truncated) + needed <= available:
                truncated = part + "/" + truncated
            else:
                # Can't fit more, stop
                break

    return emoji + "../" + truncated if emoji else "../" + truncated


def _rewrite_title(title: str) -> str:
    new_title = ""
    if "~" == title:
        new_title = icons["home"]
    elif title.startswith("~"):
        new_title = icons["home"] + title[2:]
    elif "/tmp" in title:
        new_title = icons["trash"]
    elif title.startswith("ssh") or "@" in title:
        # Handle both "ssh hostname" and "user@hostname" formats
        pattern = re.compile(r"^ssh (\w+)")
        match = re.search(pattern, title)
        if match:
            new_title = icons["ssh"] + " " + match.group(1)
        else:
            # Extract hostname from "user@hostname" format
            at_pattern = re.compile(r"@([\w\.-]+)")
            at_match = re.search(at_pattern, title)
            if at_match:
                new_title = icons["ssh"] + " " + at_match.group(1)
            else:
                return title
    else:
        return title

    return new_title


def _get_tab_metadata():
    try:
        tab_manager = get_boss().active_tab_manager
        if tab_manager:
            num_tabs = len(tab_manager.tabs)
            for i, t in enumerate(tab_manager.tabs, 1):
                if t.id == tab_manager.active_tab.id:
                    return num_tabs, i
        return 1, 1
    except:
        return 1, 1


def _draw_tabbar(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    index: int,
    extra_data: ExtraData,
) -> int:
    if tab.is_active:
        tab_fg = colors["active_fg"]
        tab_bg = colors["active_bg"]
    else:
        tab_fg = colors["fg"]
        tab_bg = colors["bg"]
    bar_bg = colors["bar_bg"]

    screen.cursor.fg, screen.cursor.bg = tab_bg, bar_bg
    screen.draw(symbols["separator_left"])

    screen.cursor.fg, screen.cursor.bg = tab_fg, tab_bg
    screen.draw(f"{index} ")

    dynamic_width = _overflow_state["tab_width"]
    if dynamic_width and len(tab.title) > dynamic_width:
        title_length = dynamic_width - 2
        # Rewrite title first to get the emoji version
        if config["rewrite_title"]:
            new_title = _rewrite_title(tab.title)
            tab = tab._replace(title=new_title)

        # Then truncate intelligently
        tab = tab._replace(title=_truncate_path(tab.title, title_length))
    elif config["rewrite_title"]:
        new_title = _rewrite_title(tab.title)
        tab = tab._replace(title=new_title)

    draw_title(draw_data, screen, tab, index)
    _draw_window_count(screen, tab.num_window_groups)

    screen.cursor.fg, screen.cursor.bg = tab_bg, bar_bg
    screen.draw(symbols["separator_right"])
    screen.draw(opts.tab_separator)

    return screen.cursor.x


def _draw_overflow_left(screen: Screen) -> int:
    screen.cursor.fg = colors["fg"]
    screen.cursor.bg = colors["bar_bg"]
    screen.draw(" " + symbols["overflow_left"])
    return screen.cursor.x


def _draw_overflow_right(screen: Screen) -> int:
    screen.cursor.fg = colors["fg"]
    screen.cursor.bg = colors["bar_bg"]
    screen.draw(symbols["overflow_right"] + " ")
    return screen.cursor.x


def _should_skip_tab(index: int, screen_x: int, tab_area_end: int, total_tabs: int, active_tab: int) -> bool:
    overflow_indicator_width = 3
    space_needed = overflow_indicator_width if index < total_tabs else 0
    estimated_tab_width = 12
    would_overflow = (screen_x + estimated_tab_width + space_needed) > tab_area_end

    if would_overflow:
        return index != active_tab

    return False

def _initialize_state(screen: Screen):
    _draw_left(screen)
    _overflow_state["tab_area_start"] = screen.cursor.x
    _overflow_state["current_width"] = 0
    _overflow_state["overflow_triggered"] = False
    _overflow_state["visible_end"] = 0
    _overflow_state["visible_start"] = 1
    _overflow_state["tab_area_end"] = screen.columns

    num_tabs, active_tab = _get_tab_metadata()
    _overflow_state["num_tabs"] = num_tabs
    _overflow_state["total_tabs"] = num_tabs
    _overflow_state["active_tab"] = active_tab
    _overflow_state["tab_width"] = _calculate_tab_width(screen, num_tabs)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global _overflow_state

    if index == 1:
        _initialize_state(screen)

    if index < _overflow_state["visible_start"]:
        return screen.cursor.x

    if index == _overflow_state["visible_start"] and _overflow_state["visible_start"] > 1:
        _draw_overflow_left(screen)

    skip = _should_skip_tab(
        index,
        screen.cursor.x,
        _overflow_state["tab_area_end"],
        _overflow_state["total_tabs"],
        _overflow_state["active_tab"]
    )

    if skip:
        if not _overflow_state["overflow_triggered"]:
            _overflow_state["overflow_triggered"] = True
            _overflow_state["visible_end"] = index - 1
            _draw_overflow_right(screen)

        return screen.cursor.x

    if _overflow_state["visible_end"] < index:
        _overflow_state["visible_end"] = index

    pos_before = screen.cursor.x
    _draw_tabbar(draw_data, screen, tab, index, extra_data)
    pos_after = screen.cursor.x
    _overflow_state["current_width"] += (pos_after - pos_before)

    if is_last:
        if _overflow_state["visible_end"] < _overflow_state["total_tabs"] and not _overflow_state["overflow_triggered"]:
            _draw_overflow_right(screen)

    return screen.cursor.x
