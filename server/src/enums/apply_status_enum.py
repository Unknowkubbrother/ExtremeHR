from enum import Enum

class ApplyStatusEnum(str, Enum):
    WAITING = "waiting"
    VIEWED = "viewed"
    INTERVIEW = "interview"
    ACCEPTED = "accepted"
    REJECTED = "rejected"