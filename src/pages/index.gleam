import components/page
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import simplifile
import tempo
import tempo/date

pub fn view(infos: Infos) -> Element(_) {
  page.page(
    "accueil",
    html.section([attribute.id("home")], [
      html.pre(
        [attribute.class("background"), attribute.contenteditable("false")],
        background(),
      ),
      html.article([attribute.class("infos")], [
        element.element(
          "radio-picker",
          [attribute.aria_label("Radio buttons"), attribute.role("radiogroup")],
          [
            html.label([], [
              html.input([
                attribute.type_("radio"),
                attribute.name("tabs"),
                attribute.id("infos"),
                attribute.checked(True),
              ]),
              html.text("infos"),
            ]),
            html.label([], [
              html.input([
                attribute.type_("radio"),
                attribute.name("tabs"),
                attribute.id("me"),
              ]),
              html.text("me"),
            ]),
          ],
        ),
        html.div([attribute.tabindex(0), attribute.id("infos-tab")], [
          html.pre([attribute.class("command")], [
            html.span([], [html.text("[user@pablo.town ~]$ screenfetch")]),
          ]),
          html.div([attribute.class("command-result")], [
            html.pre([attribute.class("art")], [html.text(ascii_art())]),
            html.pre(
              [attribute.class("specs")],
              [
                html.br([]),
                html.strong([attribute.class("key")], [html.text("user")]),
                html.strong([], [html.text("@")]),
                html.strong([attribute.class("key")], [
                  html.text("pablo.town"),
                ]),
                html.br([]),
                html.text("---------"),
                html.br([]),
              ]
                |> list.append(key_values("Hostname", [html.text(infos.name)]))
                |> list.append(
                  key_values("Uptime", [
                    html.text(infos.birth_date |> date.to_string),
                  ]),
                )
                |> list.append(key_values(
                  "Interests",
                  infos.interests |> list.map(fn(e) { html.text(e) }),
                ))
                |> list.append(key_values(
                  "Links",
                  infos.links |> list.map(to_link),
                ))
                |> list.append(key_values("Email", [html.text(infos.email)])),
            ),
          ]),
        ]),
        html.div([attribute.tabindex(0), attribute.id("me-tab")], []),
      ]),
    ]),
    False,
  )
}

fn background() -> List(Element(_)) {
  let file_path = "data/background.txt"
  let assert Ok(file_content) = simplifile.read(file_path)
  file_content |> string.to_graphemes |> list.map(to_background_element)
}

fn to_background_element(char: String) -> Element(_) {
  case char {
    "*" | "+" | "." | "°" | "," | "`" | "'" | "\"" ->
      html.span([attribute.class("glow-toggle")], [html.text(char)])
    _ -> html.text(char)
  }
}

fn ascii_art() -> String {
  let file_path = "data/screenfetch_art.txt"
  let assert Ok(result) = simplifile.read(file_path)
  result
}

fn key_values(key: String, values: List(Element(_))) -> List(Element(_)) {
  [
    html.strong([attribute.class("key")], [html.text(key)]),
    html.text(": "),
    html.span([], values |> list.intersperse(html.text(", "))),
    html.br([]),
  ]
}

pub type Infos {
  Infos(
    name: String,
    birth_date: tempo.Date,
    interests: List(String),
    links: List(Website),
    email: String,
  )
}

pub type Website {
  Website(title: String, link: String)
}

fn to_link(website: Website) -> Element(_) {
  html.a([attribute.href(website.link)], [html.text(website.title)])
}
