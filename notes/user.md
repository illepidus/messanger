## Статистика по движку юзеров

* [messages_mk3user](https://enginestat.mvk.com/rpc_engine/16000)
* Всего шардов: 8000
* Размер снапшота: 22 GiB

| Метрика                  | На шард | На кластер | Комментарий                     |
|--------------------------|---------|------------|---------------------------------|
| Пользователи             | 94 K    | 750 M      | messages total cnt              |
| Чаты                     | 9.8 M   | 78 B       | index peers sum (x2 multiplier) |
| Сообщения                | 2.8 B   | 22 T       | messages sum (x44 mulitiplier)  |
| Чаты / пользователя      | 100     | —          |                                 |
| Сообщений / пользователя | 31 K    | —          |                                 |
| Сообщений / чат          | 290     | —          | `                               |

| Нагрузка          | На шард  | На кластер | Комментарий                                                                                                                                                                                                                                |
|-------------------|----------|------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Читающие запросы  | ~270 qps | ~4.3 M qps | в основном `getPeerNotificationsStatus`, `getChatInfo`, `getPeerMarkedMessages`, `getSublistSizesMaster`, `getPeersContactIds`, `getPeerFlags`, `getChatMessages`, `getPeerMessages`, `getSortedPeerInfosLong`, `getPeersUnreadCountersV2` |
| User-home мутации | ~61 qps  | ~490 K qps | fanout-методы вида `receiveMessagePushTL`, `addHistoryEvent`, `receiveMultipleForwardedMessages`, `markMessageDeletedForAllPushTL`, `receiveMessageNoPush`, `readMessages`                                                                 |

### Топ методов по qps на одном master-shard

| Метод                                               | Тип   | qps/master | Что делает                                                |
|-----------------------------------------------------|-------|-----------:|-----------------------------------------------------------|
| `messagesUserLong.receiveMessagePushTL`             | write |       25.3 | основная fanout-запись входящего сообщения в user-home    |
| `messagesUserLong.addHistoryEvent`                  | write |       16.8 | пишет history/longpoll event в user-home                  |
| `messagesUserLong.markMessageDeletedForAllPushTL`   | write |        7.0 | fanout удаления/скрытия сообщения для всех получателей    |
| `messagesUserLong.receiveMultipleForwardedMessages` | write |        6.1 | fanout пачки forwarded messages в user-home               |
| `messagesUserLong.receiveMessageNoPush`             | write |        3.8 | fanout записи сообщения без push-события                  |
| `messagesUserLong.readMessages`                     | write |        2.7 | пишет read state / read receipts в user-home              |
| `messagesLong.getPeerNotificationsStatus`           | read  |       39.9 | читает notification/mute status для peer'а                |
| `messagesLong.getChatInfo`                          | read  |       28.6 | читает метаинформацию по чату/peer'у                      |
| `messagesLong.getPeersContactIds`                   | read  |       21.6 | получает contact ids / список peer'ов по контактам        |
| `messagesLong.getSublistSizesMaster`                | read  |       18.8 | читает размеры саблистов/категорий peer'ов                |
| `messagesLong.getPeerFlags`                         | read  |       12.4 | читает peer flags/state                                   |
| `messagesLong.getPeerMessages`                      | read  |       11.2 | читает сообщения внутри конкретного peer'а                |
| `messagesLong.getLongpollUnreadCounterSettings`     | read  |       10.9 | читает настройки unread counters / longpoll               |
| `messagesLong.getPeerMarkedMessages`                | read  |        7.5 | читает marked/flagged messages в peer'е                   |
| `messagesLong.getSortedPeerInfosLong`               | read  |        6.8 | читает отсортированный список peer infos                  |
| `messagesLong.getChatMessages`                      | read  |        6.5 | читает сообщения чата в chat-oriented проекции            |
| `messagesLong.getTimestampKeyVersion`               | read  |        5.9 | читает timestamp/version key для клиентской синхронизации |
| `messagesLong.getTimestamp`                         | read  |        5.5 | читает user/peer timestamp для синхронизации              |
| `messagesLong.getPeersUnreadCountersV2`             | read  |        4.0 | читает unread counters по peer'ам                         |
| `messagesLong.persistentHistory`                    | read  |        2.9 | читает persistent history/event stream                    |

Вот тут пока что непонятная для меня несходимость:

1. user messages sum / chat messages sum = 44
2. sendMessage2 = 3qps / 4000 шардов [chats];
3. receiveMessage* = 25 + 3 qps / 8000 шардов [users]
4. norm(receiveMessage* / sendMessage2) = 28 * 2 / 3 = 19 (???)

Я не смог (по крайней мере пока) объяснить это иначе чем тем, что раньше было как-то по одному, а теперь как-то по другому

###