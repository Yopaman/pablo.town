import lustre/element.{type Element}
import maud
import maud/components
import mork
import simplifile

pub fn render_file(path: String) -> List(Element(a)) {
  let assert Ok(file_content) = simplifile.read(path)
  maud.render_markdown(file_content, mork.configure(), components.default())
}
