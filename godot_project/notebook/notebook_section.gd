class_name NotebookSection
extends Control


@export var section_name: String = 'Section'


var current_page: int = 0

const INSTRUCTION_PAGE_TOP := 124.0
const ENTRY_PAGE_TOP := 65.0
const FIRST_PAGE_LIMIT := 8
const OTHER_PAGE_LIMIT := 9


func _ready() -> void:
	var pages: = get_pages()
	for page_index in pages.size():
		var page := pages[page_index]
		page.entry_limit = _get_page_limit(page_index)
		_connect_page(page)
	_update_page_layout()


# It always be placed at the end
func _new_page() -> void:
	var page:NotebookPage = preload('res://notebook/notebook_page.tscn').instantiate()
	page.entry_limit = _get_page_limit(get_pages().size())
	_connect_page(page)
	
	$Pages.add_child(page)
	page.hide()
	if get_pages().size() == 1:
		page.show()


# It always be the last one
func _delete_page() -> void:
	var pages: = get_pages()
	pages[-1].queue_free()


func _handle_removed_entry(page:NotebookPage) -> void:
	if page.entries_count == 0:
		page.queue_free()


func _handle_limit_reached(page:NotebookPage) -> void:
	if page.entries_count == page.entry_limit:
		_new_page()


func _handle_entry_update(encoded:String, new_text:String) -> void:
	Notebook.player_vocab.data[section_name][encoded] = new_text


func _connect_page(page: NotebookPage) -> void:
	page.entry_updated.connect(_handle_entry_update)
	page.entry_removed.connect(_handle_removed_entry.bind(page))
	page.limit_reached.connect(_handle_limit_reached.bind(page))
	page.entry_order_changed.connect(_sync_entry_order)


func _sync_entry_order() -> void:
	var ordered := {}
	for page in get_pages():
		for entry in page.get_entries():
			ordered[entry.resshan_string] = entry.get_note()
	Notebook.player_vocab.data[section_name] = ordered


func switch_page(direction:int) -> void:
	var pages: = get_pages()
	var i = current_page - direction
	if i > pages.size() - 1 or i < 0:
		return
	show_page(i)


func show_page(index: int) -> void:
	var pages := get_pages()
	pages[current_page].hide()
	current_page = index
	pages[current_page].show()
	_update_page_layout()


func get_entry_page() -> NotebookPage:
	if get_pages().is_empty():
		_new_page()
	return get_pages()[-1]


func _has_instruction_page() -> bool:
	return has_node("Label2")


func _get_page_limit(page_index: int) -> int:
	return FIRST_PAGE_LIMIT if _has_instruction_page() and page_index == 0 else OTHER_PAGE_LIMIT


func _update_page_layout() -> void:
	if not _has_instruction_page():
		return
	$Label2.visible = current_page == 0
	$Pages.offset_top = INSTRUCTION_PAGE_TOP if current_page == 0 else ENTRY_PAGE_TOP


func get_pages() -> Array[NotebookPage]:
	var arr: Array[NotebookPage]
	arr.append_array($Pages.get_children())
	return arr
