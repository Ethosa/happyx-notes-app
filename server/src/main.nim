import
  happyx,
  db_connector/db_sqlite


# Модель запроса
# Ниже мы будем обрабатывать ее в виде JSON
model CreateNote:
  # единственное обязательное поле string
  name: string

model EditNote:
  completed: bool


regCORS:
  origins: "*"
  methods: "*"
  headers: "*"
  credentials: true


# Задаем хост и порт
serve "127.0.0.1", 5000:
  # Преднастройка сервера в gcsafe (garbage collector safe) области
  setup:
    # Подключаем базу данных
    var db = open("notes.db", "", "", "")

    # Создаем таблицу, если она не существует
    db.exec(sql"""
    CREATE TABLE IF NOT EXISTS notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(50) NOT NULL,
      completed INTEGER NOT NULL DEFAULT 0
    );
    """)
  
  # Объявляем POST запрос для создания новой заметки
  post "/note[note:CreateNote]":
    # Выведем название заметки
    echo note.name
    # Вставляем заметку в базу данных и получаем ее ID
    let id = db.insertId(sql"INSERT INTO notes (name) VALUES (?)", note.name)
    # Возвращаем ID заметки в ответе
    return {"response": id}
  
  # GET запрос для получения всех заметок
  get "/notes":
    # Список заметок:
    var notes = %*[]
    # Пробегаемся по всем строчкам:
    for row in db.rows(sql"SELECT * FROM notes"):
      # Добавляем новый элемент в список
      notes.add %*{"id": row[0].parseInt, "name": row[1], "completed": row[2] != "0"}
    # Возвращаем получившийся результат:
    return {"response": {
      "items": notes,
      "size": notes.len
    }}
  
  # PATCH запрос на изменение заметки по ее ID
  patch "/note/{noteId:int}[note:EditNote]":
    # Смотрим, есть ли такая заметка вообще
    var row = db.getRow(sql"SELECT * FROM notes WHERE id = ?", noteId)
    # заметка не найдена - возвращаем ошибку
    if row[0] == "":
      statusCode = 404
      return {"error": "заметка с таким ID не найдена"}
    # Обновляем нашу заметку
    db.exec(sql"UPDATE notes SET completed = ? WHERE id = ?", note.completed.int, noteId)
    # И возвращаем успешный статус
    return {"response": "success"}
