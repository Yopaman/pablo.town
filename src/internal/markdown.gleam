import filepath
import gleam/list
import gleam/result
import gleam/string
import glimra
import lustre/element.{type Element}
import mork
import mork/to_lustre
import pages/blog
import simplifile
import tempo
import tempo/date
import tom

pub type FrontMatterError {
  MissingField
}

type Frontmatter {
  Frontmatter(title: String, date: tempo.Date, tags: List(String))
}

fn parse_frontmatter(raw_toml: String) -> Result(Frontmatter, tom.GetError) {
  let assert Ok(parsed) = tom.parse(raw_toml)
  use title <- result.try(parsed |> tom.get_string(["title"]))
  use parsed_date <- result.try(parsed |> tom.get_string(["date"]))
  use tags <- result.try(parsed |> tom.get_array(["tags"]))
  use tags_string <- result.try(tags |> list.try_map(tom.as_string))
  Ok(Frontmatter(
    title: title,
    date: parsed_date |> date.from_string |> result.unwrap(date.unix_epoch),
    tags: tags_string,
  ))
}

pub fn from_markdown_file(
  path: String,
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> blog.Post(_) {
  let assert Ok(file_content) = simplifile.read(path)
  let id =
    path
    |> filepath.directory_name
    |> filepath.split
    |> list.drop(2)
    |> string.join("/")
  let #(frontmatter, content) = mork.split_frontmatter_from_input(file_content)
  let assert Ok(parsed_frontmatter) = parse_frontmatter(frontmatter)
  let parsed_content =
    mork.parse(content) |> to_lustre.to_lustre(syntax_highlighter)
  blog.Post(
    title: parsed_frontmatter.title,
    id: id,
    date: parsed_frontmatter.date,
    tags: parsed_frontmatter.tags,
    content: parsed_content,
  )
}

pub fn element_from_md_file(
  path: String,
  syntax_highlighter syntax_highlighter: glimra.Config(glimra.HasTheme),
) -> List(Element(_)) {
  let assert Ok(file_content) = simplifile.read(path)
  mork.parse(file_content) |> to_lustre.to_lustre(syntax_highlighter)
}
