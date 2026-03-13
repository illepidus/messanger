-- 1. Мутируемое состояние чата: маленькая строка, только hot metadata/counters
CREATE TABLE chat_state (
    chat_id              Int64 NOT NULL,
    chat_type            Uint8,          -- dm / self / multichat / channel-like
    owner_user_id        Int64,
    flags                Int64,         -- упрощение, придется развернуть
    version              Int64,         -- версия chat metadata
    next_message_id      Int64,         -- allocator chat_message_id
    next_event_id        Int64,         -- allocator outbox/event seq
    members_count        Uint32,
    last_message_id      Int64,
    last_message_ts      Timestamp,
    pinned_top_message_id Int64,
    title                Utf8,
    photo                String,
    theme                Utf8,
    description          Utf8,
    secret               Int64,
    disable_until_ts     Timestamp,
    created_at           Timestamp,
    updated_at           Timestamp,
    PRIMARY KEY (chat_id)
);

-- 2. Участники чата + per-member read state
CREATE TABLE chat_member (
    chat_id              Int64 NOT NULL,
    user_id              Int64 NOT NULL,
    member_flags         Int64,           -- упрощение, придется развернуть
    inviter_user_id      Int64,
    read_upto_message_id Int64,
    read_upto_ts         Timestamp,
    incognito_id         Int64,
    joined_at            Timestamp,
    updated_at           Timestamp,
    PRIMARY KEY (chat_id, user_id)
);

-- 3. Последняя версия сообщения для горячих чтений
CREATE TABLE chat_message (
    chat_id              Int64 NOT NULL,
    chat_message_id      Int64 NOT NULL,
    author_user_id       Int64,
    random_id            Int64,         -- client dedupe token
    latest_version       Uint32,
    created_at           Timestamp,
    updated_at           Timestamp,
    message_flags        Int64,         -- упрощение, придется развернуть
    ttl_sec              Uint32,
    payload_encoding     Uint8,          -- tl/proto/json/packed
    payload_blob         String,         -- тело + kludges + keyboard + forwards + mentions
    PRIMARY KEY (chat_id, chat_message_id)
);

-- 4. История версий для edit/replace/getVersionedMessages
CREATE TABLE chat_message_version (
    chat_id              Int64 NOT NULL,
    chat_message_id      Int64 NOT NULL,
    version              Uint32 NOT NULL,
    actor_user_id        Int64,
    created_at           Timestamp,
    message_flags        Int64,
    message_common_flags Int64,          -- упрощение, придется развернуть
    payload_encoding     Uint8,
    payload_blob         String,
    PRIMARY KEY (chat_id, chat_message_id, version)
);

-- 5. Дедупликация send по client random_id
CREATE TABLE chat_send_dedupe (
    chat_id              Int64 NOT NULL,
    author_user_id       Int64 NOT NULL,
    random_id            Int64 NOT NULL,
    chat_message_id      Int64,
    created_at           Timestamp,
    PRIMARY KEY (chat_id, author_user_id, random_id)
);

-- 6. Атомарный outbox на чат
CREATE TABLE chat_outbox (
    chat_id              Int64 NOT NULL,
    event_id             Int64 NOT NULL,   -- строго монотонный внутри чата
    event_type           Uint16,            -- SEND / EDIT / READ / MEMBER_CHANGED / PIN / ...
    actor_user_id        Int64,
    chat_message_id      Int64,
    event_ts             Timestamp,
    payload_blob         String,
    PRIMARY KEY (chat_id, event_id)
);

-- 7. В коде вроде есть max_pinned_messages = 50, но я реально не смог запинить больше 1 сообщения
CREATE TABLE chat_pin (
    chat_id              Int64 NOT NULL,
    chat_message_id      Int64 NOT NULL,
    pinned_by_user_id    Int64,
    pinned_at            Timestamp,
    PRIMARY KEY (chat_id, chat_message_id)
);