# Owned by Finance. See docs/adr/0001.
_RATES = {"DE": {"default": 0.19, "books": 0.07}, "AT": {"default": 0.20}}


def _round_half_even(x):
    return int(round(x))


def tax_for(net_cents, region, category):
    rate = _RATES[region].get(category, _RATES[region]["default"])
    return _round_half_even(net_cents * rate)
