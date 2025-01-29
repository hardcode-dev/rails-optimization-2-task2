# Case-study оптимизации

## Актуальная проблема
В нашем проекте возникла серьёзная проблема.

Необходимо было обработать файл с данными, чуть больше ста мегабайт.

У нас уже была программа на `ruby`, которая умела делать нужную обработку.

Она успешно работала на файлах размером пару мегабайт, но для большого файла она работала слишком долго, и не было понятно, закончит ли она вообще работу за какое-то разумное время.

Я решил исправить эту проблему, оптимизировав эту программу.

## Формирование метрики
Для того, чтобы понимать, дают ли мои изменения положительный эффект на быстродействие программы я придумал использовать такую метрику: *объем потребления оперативной памяти при обработке файла `data_large` в течение работы программы. Использовались файлы 100_000 строк - начальный и конечный замперы, 40_000 - промежуточные.

## Гарантия корректности работы оптимизированной программы
Программа поставлялась с тестом. Выполнение этого теста в фидбек-лупе позволяет не допустить изменения логики программы при оптимизации.

## Feedback-Loop
Для того, чтобы иметь возможность быстро проверять гипотезы я выстроил эффективный `feedback-loop`, который позволил мне получать обратную связь по эффективности сделанных изменений за 1 min.

Вот как я построил `feedback_loop`: *как вы построили feedback_loop*
benchmarking.rb
memory-profiler
ruby-prof_call_grind + ruby-prof_call_stack
Refactoring
Test
benchmarking.rb
ruby-prof_call_stack

## Вникаем в детали системы, чтобы найти главные точки роста
Для того, чтобы найти "точки роста" для оптимизации я воспользовался *memory-profiler ruby-prof_call_grind + ruby-prof_call_stack*

Вот какие проблемы удалось найти и решить

### Ваша находка №0
Перевод программы на потоковый подход (File.foreach вместо File.read) значимо на объем памяти и время выполнения не повлиял

Стартовое значение метрики (40_000)
# MEMORY USAGE: 316 MB
# Finish in 16.95

### Ваша находка №1
memory-profiler:
MEMORY USAGE: 5425 MB
Total allocated: 6.70 GB (2039801 objects)
allocated memory by location: 
4.59 GB: `sessions = sessions + [parse_session(line)] if cols[0] == 'session'`
1.55 GB: user_sessions = sessions.select { |session| session['user_id'] == user['id'] }

allocated objects by location:
611814 - { 'dates' => user.sessions.map{|s| s['date']}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 } }

Allocated String Report:
144564  " " - 154
107718  "session" - 61

stackprof - менее информативен, далее не пользуемся
ruby-prof flat - менее информативен, далее не пользуемся
ruby-prof graph - неплохой, пользуемся как вспомогательным
ruby-prof call_stack - отличный в плане визуала, пользуемся как вторым основным, graph не нужен
2 точки роста:
54% - Object#collect_stats_from_users
  -> 26% - Date#parse
42% - Foreach#each
  -> 14% - #parse_session
ruby-prof call_grind - просто лучший, хотя дольше вызывать, пользуем только его и memory-profiler

- как вы решили её оптимизировать
Array#<< вместо Array#+ в `sessions = sessions + [parse_session(line)] if cols[0] == 'session'`

- как изменилась метрика: уменьшилась в 2 раза
# MEMORY USAGE: 179 MB

- как изменился отчёт профилировщика
memory-profiler:
1.6MB: `sessions = sessions + [parse_session(line)] if cols[0] == 'session'`

### Ваша находка №2
- какой отчёт показал главную точку роста
memory-profiler:
Total allocated: 1.96 GB (1959801 objects)
1.66 GB: user_sessions = sessions.select { |session| session['user_id'] == user['id'] }
allocated memory by class
-----------------------------------
   1.69 GB  Array
  66.92 MB  String

call_stack:
56% - Object#collect_stats_from_users
  -> Array#each
    -> Array#map
      -> Data#parse

- как вы решили её оптимизировать
Снова идем за memory-profiler: в Array#each с #select меняем Array#+ на Array#<<. Эффект однако небоьшой, проблема - 
в неприлично разбухающем количестве select-массивов при итерации юзеров. Поэтому заменил их промежуточным хэшем с одним проходом по sessions, из которого потом удобно формировать хэш юзеров.

- как изменилась метрика
# MEMORY USAGE: 65 MB: в 3 раза
# Finish in 0.38

- как изменился отчёт профилировщика
1.18 MB:)
allocated memory by class
-----------------------------------
  67.16 MB  String
  28.59 MB  Hash
  26.59 MB  Array

### Ваша находка №3
- какой отчёт показал главную точку роста
Возвращаемся к отчетам ruby-prof, который теперь более показательные чем memory-profiler
memory-profiler:
48.05 MB - #map
call_stack:
56% - Object#collect_stats_from_users
  -> Array#each
    -> Array#map
      -> Date#parse
Array#map [67551 calls, 67553 total]

Слишком много map
- как вы решили её оптимизировать
Убираем лишние maps при вызовах Object#collect_stats_from_users, также уберем Date.parse

- как изменилась метрика: меньше, чем хотелось бы
MEMORY USAGE: 53 MB
Finish in 0.25

- как изменился отчёт профилировщика
18% - Object#collect_stats_from_users
Array#map [6141 calls, 12284 total]

### Ваша находка №4
- какой отчёт показал главную точку роста
memory-profiler:
19MB: fields = session.split(',')
16MB: cols = line.split(',')

ruby-call-stack:
31.37% (41.21%) Object#parse_session [33859 calls, 33859 total]
21.96% (70.00%) String#split [33859 calls, 80000 total]

Проблема - в String#split в parse_session и parse_user
Убрал лишние #split, но лучше не стало
- как изменился отчёт профилировщика
28.85% (100.00%) Array#each [1 calls, 6144 total]
29.96 MB  String
14.36 MB  Array
 9.24 MB  Hash
Попробуем убрать лишние хранилища данные - хэши и массивы: в частности - промежуточный объект sessions и плохую сборку уникальных массивов

- как изменилась метрика: никак, но скорость уменьшилась более, чем двукратно (за счет удаления лишних переборов), однако на для памяти по сравнению с тем, чем она уже забита, это - ничто. И это первый вывод - смотри что оптимизируешь!

data_40k.txt
MEMORY USAGE: 51 MB
Finish in 0.1

data_large.txt
MEMORY USAGE: 1889 MB
Finish in 17.85

### Ваша находка №6
И тут я вспомнил, что забыл поменять запись файла на потоковую:(
- как вы решили её оптимизировать
Поменял запись
- как изменилась метрика: с одной стороны не сильно, но с другой - очевидно, что поменялась асимптотика
data_40k.txt
MEMORY USAGE: 29 MB
Finish in 0.2

data_large.txt
MEMORY USAGE: 31 MB
Finish in 15.81

- как изменился отчёт профилировщика
66.8MB - File.write
19MB - String.split
В целом значимых точек роста нет. Можно еще поработать со строками: #start_with?, символы в хэшах и проч., но во-первых все это уже делал, во-вторых - очевидно, что значимого влияния не будет и временные затраты себя не оправдают, и в-главных - бюджет достигнут с 31MB при необходимых 70, важно во-время остановится)

## Результаты
В результате проделанной оптимизации наконец удалось обработать файл с данными.
Удалось улучшить метрику системы с *634 MB до 30MB для 100_000 строк, data_large.txt: 31MB* и уложиться в заданный бюджет.

*Какими ещё результами можете поделиться*
String#split - тяжелый, Array#<< - эффективный, потоки хороши (как обычно), всегда смотри что оптимизруешь)

Massif
❯ ./profile.sh
==1== Massif, a heap profiler
==1== Copyright (C) 2003-2015, and GNU GPL'd, by Nicholas Nethercote
==1== Using Valgrind-3.12.0.SVN and LibVEX; rerun with -h for copyright info
==1== Command: ruby main.rb
==1== 
MEMORY USAGE: 52 MB (37 MB on Visualizer)
==1== 

## Защита от регрессии производительности
Для защиты от потери достигнутого прогресса при дальнейших изменениях программы *о performance-тестах, которые вы написали*: perormance.rb
