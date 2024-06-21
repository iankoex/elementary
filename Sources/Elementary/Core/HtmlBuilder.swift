@resultBuilder public struct HTMLBuilder {
    public static func buildExpression<Content>(_ content: Content) -> Content where Content: HTML {
        content
    }

    public static func buildExpression<Content>(_ content: Content) -> HTMLText<Content> where Content: StringProtocol {
        HTMLText(content)
    }

    public static func buildBlock() -> EmptyHTML {
        EmptyHTML()
    }

    public static func buildBlock<Content>(_ content: Content) -> Content where Content: HTML {
        content
    }

    public static func buildBlock<each Content>(_ content: repeat each Content) -> _HTMLTuple < repeat each Content> where repeat each Content: HTML {
        _HTMLTuple(repeat each content)
    }

    public static func buildIf<Content>(_ content: Content?) -> Content? where Content: HTML {
        content
    }

    public static func buildEither<TrueContent: HTML, FalseContent: HTML>(first: TrueContent) -> _HTMLConditional<TrueContent, FalseContent> {
        _HTMLConditional(.trueContent(first))
    }

    public static func buildEither<TrueContent: HTML, FalseContent: HTML>(second: FalseContent) -> _HTMLConditional<TrueContent, FalseContent> {
        _HTMLConditional(.falseContent(second))
    }

    public static func buildArray(_ components: [some HTML]) -> some HTML {
        return _HTMLArray(components)
    }
}

@_spi(Rendering)
public extension HTML where Content == Never {
    var content: Never {
        fatalError("content cannot be called on \(Self.self)")
    }
}

extension Never: HTML {
    public typealias Tag = Never
    public typealias Content = Never
}

extension Optional: HTML where Wrapped: HTML {
    @_spi(Rendering)
    public static func _render<Renderer: _HTMLRendering>(_ html: consuming Self, into renderer: inout Renderer, with context: consuming _RenderingContext) {
        switch html {
        case .none: return
        case let .some(value): Wrapped._render(value, into: &renderer, with: context)
        }
    }
}

public struct EmptyHTML: HTML {
    public init() {}

    @_spi(Rendering)
    public static func _render<Renderer: _HTMLRendering>(_ html: consuming Self, into renderer: inout Renderer, with context: consuming _RenderingContext) {
        context.assertNoAttributes(self)
    }
}

public struct HTMLText<SP: StringProtocol>: HTML {
    public var text: SP

    public init(_ text: SP) {
        self.text = text
    }

    @_spi(Rendering)
    public static func _render<Renderer: _HTMLRendering>(_ html: consuming Self, into renderer: inout Renderer, with context: consuming _RenderingContext) {
        context.assertNoAttributes(self)
        renderer.appendToken(.text(String(html.text)))
    }
}

public struct _HTMLConditional<TrueContent: HTML, FalseContent: HTML>: HTML {
    enum Value {
        case trueContent(TrueContent)
        case falseContent(FalseContent)
    }

    let value: Value

    init(_ value: Value) {
        self.value = value
    }

    @_spi(Rendering)
    public static func _render<Renderer: _HTMLRendering>(_ html: consuming Self, into renderer: inout Renderer, with context: consuming _RenderingContext) {
        switch html.value {
        case let .trueContent(content): return TrueContent._render(content, into: &renderer, with: context)
        case let .falseContent(content): return FalseContent._render(content, into: &renderer, with: context)
        }
    }
}

public extension _HTMLConditional where TrueContent.Tag == FalseContent.Tag {
    typealias Tag = TrueContent.Tag
}

public struct _HTMLTuple<each Child: HTML>: HTML {
    let value: (repeat each Child)

    init(_ value: repeat each Child) {
        self.value = (repeat each value)
    }

    @_spi(Rendering)
    public static func _render<Renderer: _HTMLRendering>(_ html: consuming Self, into renderer: inout Renderer, with context: consuming _RenderingContext) {
        context.assertNoAttributes(self)

        func renderElement<Element: HTML>(_ element: Element, _ renderer: inout some _HTMLRendering) {
            Element._render(element, into: &renderer, with: copy context)
        }
        repeat renderElement(each html.value, &renderer)
    }
}

public struct _HTMLArray<Element: HTML>: HTML {
    let value: [Element]

    init(_ value: [Element]) {
        self.value = value
    }

    @_spi(Rendering)
    public static func _render<Renderer: _HTMLRendering>(_ html: consuming Self, into renderer: inout Renderer, with context: consuming _RenderingContext) {
        context.assertNoAttributes(self)

        for element in html.value {
            Element._render(element, into: &renderer, with: copy context)
        }
    }
}
