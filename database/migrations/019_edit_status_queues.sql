ALTER TABLE queues
MODIFY COLUMN status ENUM('waiting','in_room','done','skipped')
DEFAULT 'waiting';
