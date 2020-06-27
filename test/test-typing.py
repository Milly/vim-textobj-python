from typing import Generic, List, Tuple, TypeVar

T = TypeVar('T')
S = TypeVar('S')


class ClassWithTyping(Generic[T]):
    pass


class ClassWithTypings(Generic[T, S]):
    # ClassWithTyping
    pass


def function_with_typing(foo: str) -> None:
    pass


def function_with_typings(foo: str, bar: int) -> None:
    # function_with_typings
    pass


def oneliner_with_typing(foo: str) -> None: pass


def function_with_multiline_typings(
    foo: str,
    bar: List[int],
    baz: T, qux: S,
) -> Tuple[
    str, # comment
    Tuple[
        int,
        int,
    ],
    # comment
    T, S,
]:
    # function_with_multiline_typings
    pass


def oneliner_with_multiline_typings(
    foo: str,
    bar: List[int],
    baz: T, qux: S,
) -> Tuple[
    str, # comment
    Tuple[
        int,
        int,
    ],
    # comment
    T, S,
]: pass


class ClassWithMultilineTypings(Generic[
        T, # comment
        # comment
        S,
]):
    # ClassWithMultilineTypings
    pass


class RegularClass():
    def foo(self):
        pass

    def method_with_typing(self, bar: str) -> None:
        pass

    def method_with_multiline_typings(
        self,
        foo: str,
        bar: List[int],
        baz: T, qux: S,
    ) -> Tuple[
        str, # comment
        Tuple[
            int,
            int,
        ],
        # comment
        T, S,
    ]:
        # method_with_multiline_typings
        pass


def at_end_of_file():
    pass
