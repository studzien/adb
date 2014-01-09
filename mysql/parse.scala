object Main extends App {

implicit class Regex(sc: StringContext) {
  def r = new util.matching.Regex(sc.parts.mkString, sc.parts.tail.map(_ => "x"): _*)
}

import scala.io.Source
import java.io._
val writer = new PrintWriter(new File("inserts.sql" ))

writer.write("use slic;\n")
writer.write("START TRANSACTION;\n")

for(line <- Source.fromFile("100_gs_e.pl").getLines()) {
  line match {
    case r"v.(.)${t}..(\d*)${id}.*" => writer.write("CALL add_vertex('" + t + "', " + id + ");\n")
    case r"e.(.)${from}..(\d*)${fromId}..(.)${to}..(\d*)${toId}.." => writer.write("CALL add_edge('" + from + to + "', " + fromId + ", " + toId + ");\n")
    case r"e.(.)${from}..(\d*)${fromId}..(.)${to}..(\d*)${toId}..([a-zA-Z0-9_]*)${label}.*" => writer.write("CALL add_edge_label('" + from + to + "', " + fromId + ", " + toId + ", '" + label + "');\n")
    case s => println(s)
  }
}

writer.write("COMMIT;\n")
writer.close()

}

