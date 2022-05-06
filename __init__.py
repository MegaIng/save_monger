from __future__ import annotations

from typing import TypedDict, Literal


class Point(TypedDict):
    x: int
    y: int


class ParseComponent(TypedDict):
    kind: str
    position: Point
    rotation: int
    real_offset: int
    permanent_id: int
    custom_string: str
    custom_id: int
    nudge_on_add: Point
    setting_1: int
    setting_2: int
    selected_programs: dict[int, str]


class ParseWire(TypedDict):
    path: list[Point]
    kind: Literal["wk_1", "wk_8", "wk_16", "wk_32", "wk_64"]
    color: int
    comment: str


class ParseResult(TypedDict):
    components: list[ParseComponent]
    wires: list[ParseWire]
    save_version: int
    gate: int
    delay: int
    menu_visible: bool
    clock_speed: int
    dependencies: list[int]
    description: str
    camera_position: Point
    player_data: list[int] | bytes
    image_data: list[int] | bytes


def is_virtual(component_kind: str | int) -> bool:
    pass


def parse_state(input: bytes, meta_only: bool, solution: bool) -> ParseResult:
    pass


def state_to_binary(save_version: int,
                    components: list[ParseComponent],
                    wires: list[ParseWire],
                    gate: int,
                    delay: int,
                    menu_visible: bool,
                    clock_speed: int,
                    description: str,
                    camera_position: Point,
                    player_data: list[int] | bytes) -> bytes:
    pass


from save_monger.save_monger import is_virtual, state_to_binary, parse_state