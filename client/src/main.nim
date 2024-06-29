import
  happyx,
  std/strformat,
  std/jsfetch,
  std/asyncjs,
  std/sugar,
  std/httpcore,
  std/json


# базовый URL для API
const BASE = "http://localhost:5000"

# тип для заметки
type Note = object
  id: cint
  name: cstring
  completed: bool


var
  # реактивный список заметок
  notes = remember newSeq[Note]()
  # реактивное название для новой заметки
  newName = remember ""


proc updateNotes() {.async.} =
  # Делаем запрос к серверу на получение всех заметок
  await fetch(fmt"{BASE}/notes".cstring)
    # Получаем JSON
    .then((response: Response) => response.json())
    .then(proc(data: JsObject) =
      # Преобразуем JSON в список Note
      var tmpNotes: seq[Note] = collect:
        for i in data["response"]["items"]:
          i.to(Note)
      # Если размер списка не изменился - просто меняем параметры
      if notes.len == tmpNotes.len:
        for i in 0..<tmpNotes.len:
          notes[i] = tmpNotes[i]
      else:
        # Если размер списка изменился - полностью меняем список
        notes.set(tmpNotes)
    )


proc toggleNote(note: Note) {.async.} =
  # Отправляем PATCH запрос
  discard await fetch(fmt"{BASE}/note/{note.id}".cstring, newfetchOptions(
    HttpPatch, $(%*{"completed": not note.completed})
  ))


proc addNote(name: string) {.async.} =
  # Отправляем POST запрос
  discard await fetch(fmt"{BASE}/note".cstring, newfetchOptions(
    HttpPost, $(%*{"name": name})
  ))

# Сразу получаем список заметок
discard updateNotes()


# Объявляем наше одностраничное приложение в элементе с ID app
appRoutes "app":
  # Главный маршрут
  "/":
    tDiv(class = "flex flex-col gap-2 w-fit p-8"):
      tDiv(class = "flex"):
        # input для 
        tInput(id = "newNameChanger", class = "rounded-l-full px-6 py-2 border-2 outline-none", value = $newName):
          @input:
            # Меняем название заметки
            newName.set($ev.target.InputElement.value)
        tButton(class = "bg-green-400 hover:bg-green-500 active:bg-green-600 rounded-r-full px-4 py-2 transition-all duration-300"):
          "Добавить"
          @click:
            # Добавляем новую заметку
            discard addNote(newName).then(() => (discard updateNotes()))
            newName.set("")
      tDiv(class = "flex flex-col gap-2"):
        # Пробегаемся по заметкам
        for i in 0..<notes.len:
          tDiv(
            class =
              # Меняем класс в зависимости от выполненности заметки
              if notes[i].completed:
                "rounded-full select-none px-6 py-2 cursor-pointer hover:scale-110 translation-all duration-300 bg-green-300"
              else:
                "rounded-full select-none px-6 py-2 cursor-pointer hover:scale-110 translation-all duration-300 bg-red-300"
          ):
            # аналогично с эмоджи
            if notes[i].completed:
              "✅ "
            else:
              "❌ "
            {notes[i].name}
            @click:
              # При нажатии шлем PATCH запрос и обновляем список заметок
              discard toggleNote(notes[i]).then(() => (discard updateNotes()))
