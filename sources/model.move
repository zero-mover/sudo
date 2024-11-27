module sudo::model {
    public struct RebaseFeeModel has key {
        id: 0x2::object::UID,
        base: sudo::rate::Rate,
        multiplier: sudo::decimal::Decimal,
    }

    public struct ReservingFeeModel has key {
        id: 0x2::object::UID,
        multiplier: sudo::decimal::Decimal,
    }

    public struct FundingFeeModel has key {
        id: 0x2::object::UID,
        multiplier: sudo::decimal::Decimal,
        max: sudo::rate::Rate,
    }

    public fun compute_funding_fee_rate(arg0: &FundingFeeModel, arg1: sudo::sdecimal::SDecimal, arg2: u64) : sudo::srate::SRate {
        let mut v0 = sudo::decimal::to_rate(sudo::decimal::mul(arg0.multiplier, sudo::sdecimal::value(&arg1)));
        if (sudo::rate::gt(&v0, &arg0.max)) {
            v0 = arg0.max;
        };
        sudo::srate::from_rate(!sudo::sdecimal::is_positive(&arg1), sudo::rate::div_by_u64(sudo::rate::mul_with_u64(v0, arg2), 28800))
    }

    public fun compute_rebase_fee_rate(arg0: &RebaseFeeModel, arg1: bool, arg2: sudo::rate::Rate, arg3: sudo::rate::Rate) : sudo::rate::Rate {
        if (arg1 && sudo::rate::le(&arg2, &arg3) || !arg1 && sudo::rate::ge(&arg2, &arg3)) {
            arg0.base
        } else {
            sudo::rate::add(arg0.base, sudo::decimal::to_rate(sudo::decimal::mul_with_rate(arg0.multiplier, sudo::rate::diff(arg2, arg3))))
        }
    }

    public fun compute_reserving_fee_rate(arg0: &ReservingFeeModel, arg1: sudo::rate::Rate, arg2: u64) : sudo::rate::Rate {
        sudo::rate::div_by_u64(sudo::rate::mul_with_u64(sudo::decimal::to_rate(sudo::decimal::mul_with_rate(arg0.multiplier, arg1)), arg2), 28800)
    }

    public(package) fun create_funding_fee_model(arg0: sudo::decimal::Decimal, arg1: sudo::rate::Rate, arg2: &mut 0x2::tx_context::TxContext) : 0x2::object::ID {
        let v0 = 0x2::object::new(arg2);
        let v1 = 0x2::object::uid_to_inner(&v0);
        let v2 = FundingFeeModel{
            id         : v0,
            multiplier : arg0,
            max        : arg1,
        };
        0x2::transfer::share_object<FundingFeeModel>(v2);
        v1
    }

    public(package) fun create_rebase_fee_model(arg0: sudo::rate::Rate, arg1: sudo::decimal::Decimal, arg2: &mut 0x2::tx_context::TxContext) : 0x2::object::ID {
        let v0 = 0x2::object::new(arg2);
        let v1 = 0x2::object::uid_to_inner(&v0);
        let v2 = RebaseFeeModel{
            id         : v0,
            base       : arg0,
            multiplier : arg1,
        };
        0x2::transfer::share_object<RebaseFeeModel>(v2);
        v1
    }

    public(package) fun create_reserving_fee_model(arg0: sudo::decimal::Decimal, arg1: &mut 0x2::tx_context::TxContext) : 0x2::object::ID {
        let v0 = 0x2::object::new(arg1);
        let v1 = 0x2::object::uid_to_inner(&v0);
        let v2 = ReservingFeeModel{
            id         : v0,
            multiplier : arg0,
        };
        0x2::transfer::share_object<ReservingFeeModel>(v2);
        v1
    }

    public entry fun update_funding_fee_model(arg0: &sudo::admin::AdminCap, arg1: &mut FundingFeeModel, arg2: u256, arg3: u128, arg4: &mut 0x2::tx_context::TxContext) {
        arg1.multiplier = sudo::decimal::from_raw(arg2);
        arg1.max = sudo::rate::from_raw(arg3);
    }

    public entry fun update_rebase_fee_model(arg0: &sudo::admin::AdminCap, arg1: &mut RebaseFeeModel, arg2: u128, arg3: u256, arg4: &mut 0x2::tx_context::TxContext) {
        arg1.base = sudo::rate::from_raw(arg2);
        arg1.multiplier = sudo::decimal::from_raw(arg3);
    }

    public entry fun update_reserving_fee_model(arg0: &sudo::admin::AdminCap, arg1: &mut ReservingFeeModel, arg2: u256, arg3: &mut 0x2::tx_context::TxContext) {
        arg1.multiplier = sudo::decimal::from_raw(arg2);
    }

    // decompiled from Move bytecode v6
}

