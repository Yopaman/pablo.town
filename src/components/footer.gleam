import birl
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn footer() -> Element(_) {
  html.footer([], [
    html.p([], [
      html.text(
        "pablo.town - built on "
        <> birl.now() |> birl.to_naive_date_string()
        <> " with ",
      ),
      html.a([attribute.href("https://github.com/lustre-labs/ssg")], [
        html.text("lustre/ssg"),
      ]),
    ]),
  ])
}
