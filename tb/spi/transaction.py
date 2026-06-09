from dataclasses import dataclass

from forastero import BaseTransaction

@dataclass(kw_only=True)
class SpiTrans(BaseTransaction):
    #bytes: int = 1
    data: int = 0


@dataclass(kw_only=True)
class SpiResetTrans(BaseTransaction):
    reset: bool = True