import components/footer.{footer}
import components/header.{header}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn page(title: String, content: Element(_)) -> Element(_) {
  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width,initial-scale=1"),
      ]),
      html.title([], title),
      html.link([attribute.rel("stylesheet"), attribute.href("/css/main.css")]),
    ]),
    html.body([], [header(), content, footer()]),
  ])
}
