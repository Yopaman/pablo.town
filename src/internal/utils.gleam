import gleam/int
import gleam/time/calendar
import gleam/time/timestamp
import lustre/element.{type Element}
import maud
import maud/components
import mork
import simplifile

pub fn render_file(path: String) -> List(Element(a)) {
  let assert Ok(file_content) = simplifile.read(path)
  maud.render_markdown(file_content, mork.configure(), components.default())
}

pub fn timestamp_to_string(ts: timestamp.Timestamp) -> String {
  let #(date, _) = ts |> timestamp.to_calendar(calendar.local_offset())
  date.year |> int.to_string
  <> "-"
  <> date.month |> calendar.month_to_int() |> int.to_string
  <> "-"
  <> date.day |> int.to_string
}
