module sudo::srate {
    public struct SRate has copy, drop, store {
        is_positive: bool,
        value: sudo::rate::Rate,
    }

    public fun add(arg0: SRate, arg1: SRate) : SRate {
        if (is_zero(&arg0)) {
            return arg1
        };
        if (is_zero(&arg1)) {
            return arg0
        };
        let (mut v0, mut v1) = if (arg0.is_positive == arg1.is_positive) {
            (arg0.is_positive, sudo::rate::add(arg0.value, arg1.value))
        } else if (sudo::rate::gt(&arg0.value, &arg1.value)) {
            (arg0.is_positive, sudo::rate::sub(arg0.value, arg1.value))
        } else {
            (arg1.is_positive, sudo::rate::sub(arg1.value, arg0.value))
        };
        SRate{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun div_by_u64(arg0: SRate, arg1: u64) : SRate {
        SRate{
            is_positive : arg0.is_positive,
            value       : sudo::rate::div_by_u64(arg0.value, arg1),
        }
    }

    public fun eq(arg0: &SRate, arg1: &SRate) : bool {
        sudo::rate::eq(&arg0.value, &arg1.value) && (is_zero(arg0) || arg0.is_positive == arg1.is_positive)
    }

    public fun is_zero(arg0: &SRate) : bool {
        sudo::rate::is_zero(&arg0.value)
    }

    public fun mul_with_u64(arg0: SRate, arg1: u64) : SRate {
        SRate{
            is_positive : arg0.is_positive,
            value       : sudo::rate::mul_with_u64(arg0.value, arg1),
        }
    }

    public fun sub(arg0: SRate, arg1: SRate) : SRate {
        if (is_zero(&arg0)) {
            return from_rate(!arg1.is_positive, arg1.value)
        };
        if (is_zero(&arg1)) {
            return arg0
        };
        let (mut v0, mut v1) = if (arg0.is_positive != arg1.is_positive) {
            (arg0.is_positive, sudo::rate::add(arg0.value, arg1.value))
        } else if (sudo::rate::gt(&arg0.value, &arg1.value)) {
            (arg0.is_positive, sudo::rate::sub(arg0.value, arg1.value))
        } else {
            (!arg0.is_positive, sudo::rate::sub(arg1.value, arg0.value))
        };
        SRate{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun zero() : SRate {
        SRate{
            is_positive : true,
            value       : sudo::rate::zero(),
        }
    }

    public fun add_with_rate(arg0: SRate, arg1: sudo::rate::Rate) : SRate {
        if (is_zero(&arg0)) {
            return from_rate(true, arg1)
        };
        let (mut v0, mut v1) = if (arg0.is_positive) {
            (true, sudo::rate::add(arg0.value, arg1))
        } else if (sudo::rate::gt(&arg0.value, &arg1)) {
            (false, sudo::rate::sub(arg0.value, arg1))
        } else {
            (true, sudo::rate::sub(arg1, arg0.value))
        };
        SRate{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun from_rate(arg0: bool, arg1: sudo::rate::Rate) : SRate {
        SRate{
            is_positive : arg0,
            value       : arg1,
        }
    }

    public fun is_positive(arg0: &SRate) : bool {
        arg0.is_positive
    }

    public fun sub_with_rate(arg0: SRate, arg1: sudo::rate::Rate) : SRate {
        if (is_zero(&arg0)) {
            return from_rate(false, arg1)
        };
        let (mut v0, mut v1) = if (arg0.is_positive) {
            if (sudo::rate::gt(&arg0.value, &arg1)) {
                (true, sudo::rate::sub(arg0.value, arg1))
            } else {
                (false, sudo::rate::sub(arg1, arg0.value))
            }
        } else {
            (false, sudo::rate::add(arg0.value, arg1))
        };
        SRate{
            is_positive : v0,
            value       : v1,
        }
    }

    public fun value(arg0: &SRate) : sudo::rate::Rate {
        arg0.value
    }

    // decompiled from Move bytecode v6
}

