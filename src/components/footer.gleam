import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import tempo/date

pub fn footer() -> Element(_) {
  html.footer([], [
    html.p([], [
      html.text(
        "pablo.town - built on "
        <> date.current_local() |> date.to_string
        <> " with ",
      ),
      html.a([attribute.href("https://github.com/lustre-labs/ssg")], [
        html.text("lustre/ssg"),
      ]),
    ]),
  ])
}
