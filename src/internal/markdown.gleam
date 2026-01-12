import birl
import gleam/list
import gleam/result
import mork
import mork/document
import pages/blog
import simplifile
import tom

pub type FrontMatterError {
  MissingField
}

type Frontmatter {
  Frontmatter(title: String, id: String, date: birl.Time, tags: List(String))
}

fn parse_frontmatter(raw_toml: String) -> Result(Frontmatter, tom.GetError) {
  let assert Ok(parsed) = tom.parse(raw_toml)
  use title <- result.try(parsed |> tom.get_string(["title"]))
  use id <- result.try(parsed |> tom.get_string(["id"]))
  use date <- result.try(parsed |> tom.get_string(["date"]))
  use tags <- result.try(parsed |> tom.get_array(["tags"]))
  use tags_string <- result.try(tags |> list.try_map(tom.as_string))
  Ok(Frontmatter(
    title: title,
    id: id,
    date: date |> birl.from_naive |> result.unwrap(birl.unix_epoch),
    tags: tags_string,
  ))
}

pub fn from_markdown_file(path: String) -> blog.Post {
  let assert Ok(file_content) = simplifile.read(path)
  let #(frontmatter, content) = mork.split_frontmatter_from_input(file_content)
  let assert Ok(parsed_frontmatter) = parse_frontmatter(frontmatter)
  blog.Post(
    title: parsed_frontmatter.title,
    id: parsed_frontmatter.id,
    date: parsed_frontmatter.date,
    tags: parsed_frontmatter.tags,
    content: content,
  )
}
