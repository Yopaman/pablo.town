import components/footer.{footer}
import components/header.{header}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn page(
  title: String,
  content: Element(Nil),
  highlight_syntax: Bool,
  js_scripts: List(String),
) -> Element(Nil) {
  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width,initial-scale=1"),
      ]),
      html.title([], title),
      case highlight_syntax {
        False -> [
          html.link([
            attribute.rel("stylesheet"),
            attribute.href("/css/main.css"),
          ]),
        ]
        True -> [
          html.link([
            attribute.rel("stylesheet"),
            attribute.href("/css/main.css"),
          ]),
          html.link([
            attribute.rel("stylesheet"),
            attribute.href("/css/code.css"),
          ]),
        ]
      }
        |> element.fragment,
    ]),
    html.body([], [
      header(),
      content,
      footer(),
      js_scripts
        |> list.map(fn(p) {
          html.script([attribute.src(p), attribute.attribute("async", "")], "")
        })
        |> element.fragment,
    ]),
  ])
}
