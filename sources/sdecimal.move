module sudo::sdecimal {
    public struct SDecimal has copy, drop, store {
        is_positive: bool,
        value: sudo::decimal::Decimal,
    }

    public fun add(arg0: SDecimal, arg1: SDecimal) : SDecimal {
        if (is_zero(&arg0)) {
            return arg1
        };
        if (is_zero(&arg1)) {
            return arg0
        };
        let (mut v0, mut v1) = if (arg0.is_positive == arg1.is_positive) {
            (arg0.is_positive, sudo::decimal::add(arg0.value, arg1.value))
        } else if (sudo::decimal::gt(&arg0.value, &arg1.value)) {
            (arg0.is_positive, sudo::decimal::sub(arg0.value, arg1.value))
        } else {
            (arg1.is_positive, sudo::decimal::sub(arg1.value, arg0.value))
        };
        SDecimal{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun div(arg0: SDecimal, arg1: SDecimal) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive == arg1.is_positive,
            value       : sudo::decimal::div(arg0.value, arg1.value),
        }
    }

    public fun div_by_rate(arg0: SDecimal, arg1: sudo::rate::Rate) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive,
            value       : sudo::decimal::div_by_rate(arg0.value, arg1),
        }
    }

    public fun div_by_u64(arg0: SDecimal, arg1: u64) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive,
            value       : sudo::decimal::div_by_u64(arg0.value, arg1),
        }
    }

    public fun eq(arg0: &SDecimal, arg1: &SDecimal) : bool {
        sudo::decimal::eq(&arg0.value, &arg1.value) && (is_zero(arg0) || arg0.is_positive == arg1.is_positive)
    }

    public fun is_zero(arg0: &SDecimal) : bool {
        sudo::decimal::is_zero(&arg0.value)
    }

    public fun mul(arg0: SDecimal, arg1: SDecimal) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive == arg1.is_positive,
            value       : sudo::decimal::mul(arg0.value, arg1.value),
        }
    }

    public fun mul_with_rate(arg0: SDecimal, arg1: sudo::rate::Rate) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive,
            value       : sudo::decimal::mul_with_rate(arg0.value, arg1),
        }
    }

    public fun mul_with_u64(arg0: SDecimal, arg1: u64) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive,
            value       : sudo::decimal::mul_with_u64(arg0.value, arg1),
        }
    }

    public fun sub(arg0: SDecimal, arg1: SDecimal) : SDecimal {
        if (is_zero(&arg0)) {
            return from_decimal(!arg1.is_positive, arg1.value)
        };
        if (is_zero(&arg1)) {
            return arg0
        };
        let (mut v0, mut v1) = if (arg0.is_positive != arg1.is_positive) {
            (arg0.is_positive, sudo::decimal::add(arg0.value, arg1.value))
        } else if (sudo::decimal::gt(&arg0.value, &arg1.value)) {
            (arg0.is_positive, sudo::decimal::sub(arg0.value, arg1.value))
        } else {
            (!arg0.is_positive, sudo::decimal::sub(arg1.value, arg0.value))
        };
        SDecimal{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun zero() : SDecimal {
        SDecimal{
            is_positive : true,
            value       : sudo::decimal::zero(),
        }
    }

    public fun add_with_decimal(arg0: SDecimal, arg1: sudo::decimal::Decimal) : SDecimal {
        if (is_zero(&arg0)) {
            return from_decimal(true, arg1)
        };
        let (mut v0, mut v1) = if (arg0.is_positive) {
            (true, sudo::decimal::add(arg0.value, arg1))
        } else if (sudo::decimal::gt(&arg0.value, &arg1)) {
            (false, sudo::decimal::sub(arg0.value, arg1))
        } else {
            (true, sudo::decimal::sub(arg1, arg0.value))
        };
        SDecimal{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun div_by_decimal(arg0: SDecimal, arg1: sudo::decimal::Decimal) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive,
            value       : sudo::decimal::div(arg0.value, arg1),
        }
    }

    public fun div_by_srate(arg0: SDecimal, arg1: sudo::srate::SRate) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive == sudo::srate::is_positive(&arg1),
            value       : sudo::decimal::div_by_rate(arg0.value, sudo::srate::value(&arg1)),
        }
    }

    public fun from_decimal(arg0: bool, arg1: sudo::decimal::Decimal) : SDecimal {
        SDecimal{
            is_positive : arg0,
            value       : arg1,
        }
    }

    public fun from_srate(arg0: sudo::srate::SRate) : SDecimal {
        SDecimal{
            is_positive : sudo::srate::is_positive(&arg0),
            value       : sudo::decimal::from_rate(sudo::srate::value(&arg0)),
        }
    }

    public fun is_positive(arg0: &SDecimal) : bool {
        arg0.is_positive
    }

    public fun mul_with_decimal(arg0: SDecimal, arg1: sudo::decimal::Decimal) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive,
            value       : sudo::decimal::mul(arg0.value, arg1),
        }
    }

    public fun mul_with_srate(arg0: SDecimal, arg1: sudo::srate::SRate) : SDecimal {
        SDecimal{
            is_positive : arg0.is_positive == sudo::srate::is_positive(&arg1),
            value       : sudo::decimal::mul_with_rate(arg0.value, sudo::srate::value(&arg1)),
        }
    }

    public fun sub_with_decimal(arg0: SDecimal, arg1: sudo::decimal::Decimal) : SDecimal {
        if (is_zero(&arg0)) {
            return from_decimal(false, arg1)
        };
        let (mut v0, mut v1) = if (arg0.is_positive) {
            if (sudo::decimal::gt(&arg0.value, &arg1)) {
                (true, sudo::decimal::sub(arg0.value, arg1))
            } else {
                (false, sudo::decimal::sub(arg1, arg0.value))
            }
        } else {
            (false, sudo::decimal::add(arg0.value, arg1))
        };
        SDecimal{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun to_srate(arg0: SDecimal) : sudo::srate::SRate {
        sudo::srate::from_rate(arg0.is_positive, sudo::decimal::to_rate(arg0.value))
    }

    public fun value(arg0: &SDecimal) : sudo::decimal::Decimal {
        arg0.value
    }

    // decompiled from Move bytecode v6
}

