module sudo::referral {
    public struct Referral has store {
        referrer: address,
        rebate_rate: sudo::rate::Rate,
    }

    public fun get_rebate_rate(arg0: &Referral) : sudo::rate::Rate {
        arg0.rebate_rate
    }

    public fun get_referrer(arg0: &Referral) : address {
        arg0.referrer
    }

    public(package) fun new_referral(arg0: address, arg1: sudo::rate::Rate) : Referral {
        Referral{
            referrer    : arg0,
            rebate_rate : arg1,
        }
    }

    // decompiled from Move bytecode v6
}

