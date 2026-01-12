import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn header() -> Element(_) {
  html.header([], [
    html.nav([], [
      html.ul([], [
        html.li([attribute.class("nav-item")], [
          html.a([attribute.href("/")], [html.text("home")]),
        ]),
        html.li([attribute.class("title")], [
          html.a([attribute.href("/")], [html.h1([], [html.text("pablo.town")])]),
        ]),
        html.li([attribute.class("nav-item")], [
          html.a([attribute.href("/blog")], [html.text("posts")]),
        ]),
      ]),
    ]),
  ])
}
