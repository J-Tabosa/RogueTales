extends RefCounted
## Read a small, literal-value XLSX table without Excel, Python or an addon.
## Shared/inline strings, sparse cells and reordered worksheets are supported.
const MAX_XML_BYTES := 4 * 1024 * 1024

static func xml(archive: ZIPReader, path: String) -> XMLParser:
	if not archive.file_exists(path): return null
	var bytes := archive.read_file(path)
	if bytes.is_empty() or bytes.size() > MAX_XML_BYTES: return null
	var parser := XMLParser.new()
	return parser if parser.open_buffer(bytes) == OK else null

static func attribute(parser: XMLParser, key: String) -> String:
	return parser.get_named_attribute_value_safe(key)

static func node_name(parser: XMLParser) -> String:
	return parser.get_node_name().split(":")[-1]

static func worksheet(archive: ZIPReader, name: String) -> String:
	var parser := xml(archive, "xl/workbook.xml")
	if parser == null: return ""
	var relation := ""
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and node_name(parser) == "sheet" and attribute(parser, "name") == name:
			relation = attribute(parser, "r:id")
	if relation.is_empty(): return ""
	parser = xml(archive, "xl/_rels/workbook.xml.rels")
	if parser == null: return ""
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and node_name(parser) == "Relationship" and attribute(parser, "Id") == relation:
			var target := attribute(parser, "Target")
			if attribute(parser, "TargetMode") == "External": return ""
			return target.trim_prefix("/") if target.begins_with("/") else ("xl/" + target).simplify_path()
	return ""

static func strings(archive: ZIPReader) -> Array[String]:
	var result: Array[String] = []
	var parser := xml(archive, "xl/sharedStrings.xml")
	if parser == null: return result
	var text := ""
	var in_text := false
	while parser.read() == OK:
		var kind := parser.get_node_type()
		if kind == XMLParser.NODE_ELEMENT:
			if node_name(parser) == "si": text = ""
			if node_name(parser) == "t": in_text = not parser.is_empty()
		elif kind == XMLParser.NODE_TEXT and in_text: text += parser.get_node_data()
		elif kind == XMLParser.NODE_ELEMENT_END:
			if node_name(parser) == "t": in_text = false
			if node_name(parser) == "si": result.append(text)
	return result

static func column_index(reference: String) -> int:
	var value := 0
	for character in reference.to_upper():
		var code := character.unicode_at(0)
		if code < 65 or code > 90: break
		value = value * 26 + code - 64
	return value - 1

static func read_table(path: String, sheet_name := "Inimigos") -> Dictionary:
	var archive := ZIPReader.new()
	if archive.open(path) != OK: return {"error": "Não foi possível abrir a planilha XLSX."}
	var sheet_path := worksheet(archive, sheet_name)
	var parser := xml(archive, sheet_path)
	if parser == null:
		archive.close()
		return {"error": "A aba %s está ausente ou inválida." % sheet_name}
	var shared := strings(archive)
	var rows: Array = []
	var row: Dictionary = {}
	var column := -1
	var cell_type := ""
	var value := ""
	var reading_value := false
	var has_formula := false
	var error := OK
	while true:
		error = parser.read()
		if error != OK: break
		var kind := parser.get_node_type()
		var tag := node_name(parser) if kind in [XMLParser.NODE_ELEMENT, XMLParser.NODE_ELEMENT_END] else ""
		if kind == XMLParser.NODE_ELEMENT:
			match tag:
				"row": row = {}
				"c":
					column = column_index(attribute(parser, "r"))
					cell_type = attribute(parser, "t")
					value = ""
					has_formula = false
				"f": has_formula = true
				"v", "t": reading_value = not parser.is_empty()
		elif kind == XMLParser.NODE_TEXT and reading_value: value += parser.get_node_data()
		elif kind == XMLParser.NODE_ELEMENT_END:
			match tag:
				"v", "t": reading_value = false
				"c":
					if column < 0 or column > 255:
						archive.close()
						return {"error": "Referência de célula inválida."}
					if cell_type == "s":
						if not value.is_valid_int() or int(value) < 0 or int(value) >= shared.size():
							archive.close()
							return {"error": "Texto compartilhado inválido."}
						value = shared[int(value)]
					row[column] = {"value": value, "formula": has_formula, "error": cell_type == "e"}
				"row":
					if not row.is_empty(): rows.append(row)
	archive.close()
	if error != ERR_FILE_EOF: return {"error": "XML da planilha incompleto."}
	if rows.is_empty(): return {"error": "A tabela está vazia."}
	var headers: Dictionary = {}
	for at in rows[0]:
		var heading := str(rows[0][at].value).strip_edges()
		if heading.is_empty(): continue
		if headers.has(heading): return {"error": "Coluna duplicada: " + heading}
		headers[heading] = at
	var records: Array[Dictionary] = []
	for index in range(1, rows.size()):
		var record := {}
		for heading in headers:
			record[heading] = rows[index].get(headers[heading], {"value": "", "formula": false, "error": false})
		records.append(record)
	return {"headers": headers, "records": records}
