# Test scenarios for textobj-python

def regular_func(bar, baz):
    print bar

    print baz
    print "quux"


print "other_stmts"


def multiline_func_def(baz,
                       quux):
    print baz
    print quux

    print "barp"


def oneliner(): pass


def multiline_def_oneliner(asdf,
                           qwer): pass


def nested_func():
    print "foo"

    def the_inner_func():
        print "bar"
        print "foo"
    print "baz"


class TrySomething():
    def foo(self):
        try:
            print "bar"
        except Exception, e:
            print e
        finally:
            print "finally"


class RegularClass():
    def __init__(self):
        print "asdf"
        pass

    def bar(self):
        print self.bar


class NestedClass():
    class InHere():
        pass


def this_func_has_a_func():
    def foo():
        pass

    class InsideFunc():
        def __init__(self):
            pass

        def foo(self):
            print foo


def one_stmt():
    pass


class no_defs():
    """This is a long comment.

    Do a vif here, make sure it gets nothing.

    """
    pass