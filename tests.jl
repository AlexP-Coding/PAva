include("main.jl")

print_object.methods

@defclass(Foo, [], [[foo=123, reader=get_foo, writer=set_foo!]])

get_foo(new(Foo))
set_foo!(new(Foo), 4)

@defclass(CountingClass, [Class], [counter=0])

@defclass(Foo, [], [], metaclass=CountingClass)

@defclass(ColorMixin, [], [[color, reader=get_color, writer=set_color!, initform="rosa"]])

get_color(new(ColorMixin))

@defclass(ComplexNumber, [], [real, imag])

c1 = new(ComplexNumber, real=1, imag=2)

getproperty(c1, :real)
setproperty!(c1, :imag, -1)

c1.real
c1.imag
c1.imag += 3

@defgeneric add(a, b)
@defmethod add(a::ComplexNumber, b::ComplexNumber) = new(ComplexNumber, real=(a.real + b.real), imag=(a.imag + b.imag))

c2 = new(ComplexNumber, real=3, imag=4)

@defmethod print_object(c::ComplexNumber, io) = print(io, "$(c.real)$(c.imag < 0 ? "-" : "+")$(abs(c.imag))i")
c1

add(c1, c2)

class_of(c1) === ComplexNumber
ComplexNumber.direct_slots
class_of(class_of(c1)) === Class
class_of(class_of(class_of(c1))) === Class

Class.name
Class.slots
class_name(Class)
class_slots(Class)

ComplexNumber.name
ComplexNumber.direct_superclasses == [Object]

add
add.name
generic_name(add)
add.parameters
generic_parameters(add)
add.methods
generic_methods(add)
class_of(add) === GenericFunction
GenericFunction.slots

class_of(add.methods[1]) === MultiMethod
MultiMethod.slots
add.methods[1]
add.methods[1].specializers
add.methods[1].generic_function === add

@defclass(UndoableClass, [Class], [])

@defclass(Person, [],
[[name, reader=get_name, writer=set_name!],
[age, reader=get_age, writer=set_age!, initform=0],
[friend, reader=get_friend, writer=set_friend!]],
metaclass=UndoableClass)

Person
class_of(Person)
class_of(class_of(Person))
get_name(new(Person))
set_name!(new(Person), 4)
get_age(new(Person))

add(123, 456)

@defclass(Circle, [], [center, radius])

@defclass(ColorMixin, [], [color])
@defclass(ColoredCircle, [ColorMixin, Circle], [])
cc = new(ColoredCircle)

# class hierarchy
ColoredCircle.direct_superclasses
ans[1].direct_superclasses
ans[1].direct_superclasses
ans[1].direct_superclasses

@defclass(A, [], [])
@defclass(B, [], [])
@defclass(C, [], [])
@defclass(D, [A, B], [])
@defclass(E, [A, C], [])
@defclass(F, [D, E], [])

compute_cpl(F)

class_of(1)
class_of("Foo")

@defmethod add(a::_Int64, b::_Int64) = a + b
@defmethod add(a::_String, b::_String) = a * b

add(1, 3)
add("Foo", "Bar")

class_name(Circle)
class_direct_slots(Circle)
class_direct_slots(ColoredCircle)
class_slots(ColoredCircle)
class_direct_superclasses(ColoredCircle)
class_cpl(ColoredCircle)

@defclass(Foo, [], [a=1, b=2])
@defclass(Bar, [], [b=3, c=4])
@defclass(FooBar, [Foo, Bar], [a=5, d=6])
class_slots(FooBar)

foobar1 = new(FooBar)

foobar1.a
foobar1.b
foobar1.c
foobar1.d

@defclass(FlavorsClass, [Class], [])

@defclass(A, [], [], metaclass=FlavorsClass)
@defclass(B, [], [], metaclass=FlavorsClass)
@defclass(C, [], [], metaclass=FlavorsClass)
@defclass(D, [A, B], [], metaclass=FlavorsClass)
@defclass(E, [A, C], [], metaclass=FlavorsClass)
@defclass(F, [D, E], [], metaclass=FlavorsClass)

compute_cpl(F)

@defclass(Shape, [], [])
@defclass(Device, [], [])

@defgeneric draw(shape, device)

@defclass(Line, [Shape], [from, to])
@defclass(Circle, [Shape], [center, radius])
@defclass(Screen, [Device], [])
@defclass(Printer, [Device], [])

@defmethod draw(shape::Line, device::Screen) = println("Drawing a Line on Screen")
@defmethod draw(shape::Circle, device::Screen) = println("Drawing a Circle on Screen")
@defmethod draw(shape::Line, device::Printer) = println("Drawing a Line on Printer")
@defmethod draw(shape::Circle, device::Printer) = println("Drawing a Circle on Printer")

generic_methods(draw)

method_specializers(generic_methods(draw)[1])

# to test the order of methods
@defmethod draw(shape::Line, device::Screen) = println("Drawing a Line on Screen")
@defmethod draw(shape::Line, device::Device) = println("Drawing a Line on Device")
@defmethod draw(shape::Shape, device::Device) = println("Drawing a Shape on Device")
@defmethod draw(shape::Shape, device::Screen) = println("Drawing a Shape on Screen")

draw(new(Line), new(Screen))

let devices = [new(Screen), new(Printer)],
    shapes = [new(Line), new(Circle)]
    for device in devices
        for shape in shapes
            draw(shape, device)
        end
    end
end

@defclass(ColorMixin, [],
[[color, reader=get_color, writer=set_color!]])

@defmethod draw(s::ColorMixin, d::Device) =
    let previous_color = get_device_color(d)
    set_device_color!(d, get_color(s))
    call_next_method()
    set_device_color!(d, previous_color)
    end

@defclass(ColoredLine, [ColorMixin, Line], [])
@defclass(ColoredCircle, [ColorMixin, Circle], [])
@defclass(ColoredPrinter, [Printer], [[ink=:black, reader=get_device_color, writer=_set_device_color!]])

@defmethod set_device_color!(d::ColoredPrinter, color) = begin
    println("Changing printer ink color to $color")
    _set_device_color!(d, color)
    end

draw.methods

let shapes = [new(Line), new(ColoredCircle, color=:red), new(ColoredLine, color=:blue)],
        printer = new(ColoredPrinter, ink=:black)
    for shape in shapes
        draw(shape, printer)
    end
end