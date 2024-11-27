module sudo::position {
    public struct PositionConfig has copy, drop, store {
        max_leverage: u64,
        min_holding_duration: u64,
        max_reserved_multiplier: u64,
        min_collateral_value: sudo::decimal::Decimal,
        open_fee_bps: sudo::rate::Rate,
        decrease_fee_bps: sudo::rate::Rate,
        liquidation_threshold: sudo::rate::Rate,
        liquidation_bonus: sudo::rate::Rate,
    }

    public struct Position<phantom T0> has store {
        closed: bool,
        config: PositionConfig,
        open_timestamp: u64,
        position_amount: u64,
        position_size: sudo::decimal::Decimal,
        reserving_fee_amount: sudo::decimal::Decimal,
        funding_fee_value: sudo::sdecimal::SDecimal,
        last_reserving_rate: sudo::rate::Rate,
        last_funding_rate: sudo::srate::SRate,
        reserved: 0x2::balance::Balance<T0>,
        collateral: 0x2::balance::Balance<T0>,
    }

    public struct OpenPositionResult<phantom T0> {
        position: Position<T0>,
        open_fee: 0x2::balance::Balance<T0>,
        open_fee_amount: sudo::decimal::Decimal,
    }

    public struct DecreasePositionResult<phantom T0> {
        closed: bool,
        has_profit: bool,
        settled_amount: u64,
        decreased_reserved_amount: u64,
        decrease_size: sudo::decimal::Decimal,
        reserving_fee_amount: sudo::decimal::Decimal,
        decrease_fee_value: sudo::decimal::Decimal,
        reserving_fee_value: sudo::decimal::Decimal,
        funding_fee_value: sudo::sdecimal::SDecimal,
        to_vault: 0x2::balance::Balance<T0>,
        to_trader: 0x2::balance::Balance<T0>,
    }

    public fun check_holding_duration<T0>(arg0: &Position<T0>, arg1: &sudo::sdecimal::SDecimal, arg2: u64) : bool {
        !sudo::sdecimal::is_positive(arg1) || arg0.open_timestamp + arg0.config.min_holding_duration <= arg2
    }

    public fun check_leverage(arg0: &PositionConfig, arg1: sudo::decimal::Decimal, arg2: u64, arg3: &sudo::agg_price::AggPrice) : bool {
        let v0 = sudo::decimal::mul_with_u64(arg1, arg0.max_leverage);
        let v1 = sudo::agg_price::coins_to_value(arg3, arg2);
        sudo::decimal::ge(&v0, &v1)
    }

    public fun check_liquidation(arg0: &PositionConfig, arg1: sudo::decimal::Decimal, arg2: &sudo::sdecimal::SDecimal) : bool {
        if (sudo::sdecimal::is_positive(arg2)) {
            false
        } else {
            let v1 = sudo::decimal::mul_with_rate(arg1, arg0.liquidation_threshold);
            let v2 = sudo::sdecimal::value(arg2);
            sudo::decimal::le(&v1, &v2)
        }
    }

    public fun closed<T0>(arg0: &Position<T0>) : bool {
        arg0.closed
    }

    public fun collateral_amount<T0>(arg0: &Position<T0>) : u64 {
        0x2::balance::value<T0>(&arg0.collateral)
    }

    public fun compute_delta_size<T0>(arg0: &Position<T0>, arg1: &sudo::agg_price::AggPrice, arg2: bool) : sudo::sdecimal::SDecimal {
        let v0 = sudo::agg_price::coins_to_value(arg1, arg0.position_amount);
        let (mut v1, mut v2) = if (sudo::decimal::gt(&v0, &arg0.position_size)) {
            (arg2, sudo::decimal::sub(v0, arg0.position_size))
        } else {
            (!arg2, sudo::decimal::sub(arg0.position_size, v0))
        };
        sudo::sdecimal::from_decimal(v1, v2)
    }

    public fun compute_funding_fee_value<T0>(arg0: &Position<T0>, arg1: sudo::srate::SRate) : sudo::sdecimal::SDecimal {
        let v0 = sudo::srate::sub(arg1, arg0.last_funding_rate);
        sudo::sdecimal::add(arg0.funding_fee_value, sudo::sdecimal::from_decimal(sudo::srate::is_positive(&v0), sudo::decimal::mul_with_rate(arg0.position_size, sudo::srate::value(&v0))))
    }

    public fun compute_reserving_fee_amount<T0>(arg0: &Position<T0>, arg1: sudo::rate::Rate) : sudo::decimal::Decimal {
        sudo::decimal::add(arg0.reserving_fee_amount, sudo::decimal::mul_with_rate(sudo::decimal::from_u64(0x2::balance::value<T0>(&arg0.reserved)), sudo::rate::sub(arg1, arg0.last_reserving_rate)))
    }

    public fun config_decrease_fee_bps(arg0: &PositionConfig) : sudo::rate::Rate {
        arg0.decrease_fee_bps
    }

    public fun config_liquidation_bonus(arg0: &PositionConfig) : sudo::rate::Rate {
        arg0.liquidation_bonus
    }

    public fun config_liquidation_threshold(arg0: &PositionConfig) : sudo::rate::Rate {
        arg0.liquidation_threshold
    }

    public fun config_max_leverage(arg0: &PositionConfig) : u64 {
        arg0.max_leverage
    }

    public fun config_max_reserved_multiplier(arg0: &PositionConfig) : u64 {
        arg0.max_reserved_multiplier
    }

    public fun config_min_collateral_value(arg0: &PositionConfig) : sudo::decimal::Decimal {
        arg0.min_collateral_value
    }

    public fun config_min_holding_duration(arg0: &PositionConfig) : u64 {
        arg0.min_holding_duration
    }

    public fun config_open_fee_bps(arg0: &PositionConfig) : sudo::rate::Rate {
        arg0.open_fee_bps
    }

    public(package) fun decrease_position<T0>(arg0: &mut Position<T0>, arg1: &sudo::agg_price::AggPrice, arg2: &sudo::agg_price::AggPrice, arg3: sudo::decimal::Decimal, arg4: bool, arg5: u64, arg6: sudo::rate::Rate, arg7: sudo::srate::SRate, arg8: u64) : (u64, 0x1::option::Option<DecreasePositionResult<T0>>) {
        if (arg0.closed) {
            return (1, 0x1::option::none<DecreasePositionResult<T0>>())
        };
        let v0 = sudo::agg_price::price_of(arg1);
        if (sudo::decimal::lt(&v0, &arg3)) {
            return (15, 0x1::option::none<DecreasePositionResult<T0>>())
        };
        if (arg5 == 0 || arg5 > arg0.position_amount) {
            return (6, 0x1::option::none<DecreasePositionResult<T0>>())
        };
        let v1 = sudo::decimal::div_by_u64(sudo::decimal::mul_with_u64(arg0.position_size, arg5), arg0.position_amount);
        let mut v2 = compute_delta_size<T0>(arg0, arg2, arg4);
        let mut v3 = sudo::sdecimal::div_by_u64(sudo::sdecimal::mul_with_u64(v2, arg5), arg0.position_amount);
        let v4 = v2;
        v2 = sudo::sdecimal::sub(v4, v3);
        if (!check_holding_duration<T0>(arg0, &v2, arg8)) {
            return (10, 0x1::option::none<DecreasePositionResult<T0>>())
        };
        let v5 = compute_reserving_fee_amount<T0>(arg0, arg6);
        let v6 = sudo::agg_price::coins_to_value(arg1, sudo::decimal::ceil_u64(v5));
        let v7 = compute_funding_fee_value<T0>(arg0, arg7);
        let v8 = sudo::decimal::mul_with_rate(v1, arg0.config.decrease_fee_bps);
        let v9 = v3;
        v3 = sudo::sdecimal::sub(v9, sudo::sdecimal::add_with_decimal(v7, sudo::decimal::add(v8, v6)));
        let mut v10 = arg5 == arg0.position_amount;
        let v11 = sudo::sdecimal::is_positive(&v3);
        let mut v12 = if (v11) {
            let v13 = sudo::decimal::floor_u64(sudo::agg_price::value_to_coins(arg1, sudo::sdecimal::value(&v3)));
            let mut v14 = v13;
            if (v13 >= 0x2::balance::value<T0>(&arg0.reserved)) {
                v10 = true;
                v14 = 0x2::balance::value<T0>(&arg0.reserved);
            };
            v14
        } else {
            let v15 = sudo::decimal::ceil_u64(sudo::agg_price::value_to_coins(arg1, sudo::sdecimal::value(&v3)));
            let mut v16 = v15;
            if (v15 >= 0x2::balance::value<T0>(&arg0.collateral)) {
                v10 = true;
                v16 = 0x2::balance::value<T0>(&arg0.collateral);
            };
            v16
        };
        let mut v17 = if (v10) {
            0x2::balance::value<T0>(&arg0.reserved)
        } else if (v11) {
            v12
        } else {
            0
        };
        let v18 = arg0.position_amount - arg5;
        if (!v10) {
            let mut v19 = if (v11) {
                0x2::balance::value<T0>(&arg0.collateral)
            } else {
                0x2::balance::value<T0>(&arg0.collateral) - v12
            };
            let v20 = sudo::agg_price::coins_to_value(arg1, v19);
            if (sudo::decimal::lt(&v20, &arg0.config.min_collateral_value)) {
                return (9, 0x1::option::none<DecreasePositionResult<T0>>())
            };
            if (!check_leverage(&arg0.config, v20, v18, arg2)) {
                return (11, 0x1::option::none<DecreasePositionResult<T0>>())
            };
            if (check_liquidation(&arg0.config, v20, &v2)) {
                return (12, 0x1::option::none<DecreasePositionResult<T0>>())
            };
        };
        arg0.closed = v10;
        arg0.position_amount = v18;
        arg0.position_size = sudo::decimal::sub(arg0.position_size, v1);
        arg0.reserving_fee_amount = sudo::decimal::zero();
        arg0.funding_fee_value = sudo::sdecimal::zero();
        arg0.last_funding_rate = arg7;
        arg0.last_reserving_rate = arg6;
        let (mut v21, mut v22) = if (v11) {
            (0x2::balance::zero<T0>(), 0x2::balance::split<T0>(&mut arg0.reserved, v12))
        } else {
            (0x2::balance::split<T0>(&mut arg0.collateral, v12), 0x2::balance::zero<T0>())
        };
        let mut v23 = v22;
        let mut v24 = v21;
        if (v10) {
            0x2::balance::join<T0>(&mut v24, 0x2::balance::withdraw_all<T0>(&mut arg0.reserved));
            0x2::balance::join<T0>(&mut v23, 0x2::balance::withdraw_all<T0>(&mut arg0.collateral));
        };
        let v25 = DecreasePositionResult<T0>{
            closed                    : v10,
            has_profit                : v11,
            settled_amount            : v12,
            decreased_reserved_amount : v17,
            decrease_size             : v1,
            reserving_fee_amount      : v5,
            decrease_fee_value        : v8,
            reserving_fee_value       : v6,
            funding_fee_value         : v7,
            to_vault                  : v24,
            to_trader                 : v23,
        };
        (0, 0x1::option::some<DecreasePositionResult<T0>>(v25))
    }

    public(package) fun decrease_reserved_from_position<T0>(arg0: &mut Position<T0>, arg1: u64, arg2: sudo::rate::Rate) : 0x2::balance::Balance<T0> {
        assert!(!arg0.closed, 1);
        assert!(arg1 < 0x2::balance::value<T0>(&arg0.reserved), 8);
        arg0.reserving_fee_amount = compute_reserving_fee_amount<T0>(arg0, arg2);
        arg0.last_reserving_rate = arg2;
        0x2::balance::split<T0>(&mut arg0.reserved, arg1)
    }

    public(package) fun destroy_position<T0>(arg0: Position<T0>) {
        let Position<T0> {
            closed               : v0,
            config               : _,
            open_timestamp       : _,
            position_amount      : _,
            position_size        : _,
            reserving_fee_amount : _,
            funding_fee_value    : _,
            last_reserving_rate  : _,
            last_funding_rate    : _,
            reserved             : v9,
            collateral           : v10,
        } = arg0;
        assert!(v0, 2);
        0x2::balance::destroy_zero<T0>(v9);
        0x2::balance::destroy_zero<T0>(v10);
    }

    public(package) fun liquidate_position<T0>(arg0: &mut Position<T0>, arg1: &sudo::agg_price::AggPrice, arg2: &sudo::agg_price::AggPrice, arg3: bool, arg4: sudo::rate::Rate, arg5: sudo::srate::SRate) : (u64, u64, u64, u64, sudo::decimal::Decimal, sudo::decimal::Decimal, sudo::decimal::Decimal, sudo::sdecimal::SDecimal, 0x2::balance::Balance<T0>, 0x2::balance::Balance<T0>) {
        assert!(!arg0.closed, 1);
        let mut v0 = compute_delta_size<T0>(arg0, arg2, arg3);
        let v1 = compute_reserving_fee_amount<T0>(arg0, arg4);
        let v2 = sudo::agg_price::coins_to_value(arg1, sudo::decimal::ceil_u64(v1));
        let v3 = compute_funding_fee_value<T0>(arg0, arg5);
        let v4 = v0;
        v0 = sudo::sdecimal::sub(v4, sudo::sdecimal::add_with_decimal(v3, v2));
        assert!(check_liquidation(&arg0.config, sudo::agg_price::coins_to_value(arg1, 0x2::balance::value<T0>(&arg0.collateral)), &v0), 13);
        let v5 = 0x2::balance::value<T0>(&arg0.collateral);
        arg0.closed = true;
        arg0.position_amount = 0;
        arg0.position_size = sudo::decimal::zero();
        arg0.reserving_fee_amount = sudo::decimal::zero();
        arg0.funding_fee_value = sudo::sdecimal::zero();
        arg0.last_funding_rate = arg5;
        arg0.last_reserving_rate = arg4;
        let v6 = sudo::decimal::floor_u64(sudo::decimal::mul_with_rate(sudo::decimal::from_u64(v5), arg0.config.liquidation_bonus));
        let mut v7 = 0x2::balance::withdraw_all<T0>(&mut arg0.reserved);
        0x2::balance::join<T0>(&mut v7, 0x2::balance::withdraw_all<T0>(&mut arg0.collateral));
        (v6, v5, arg0.position_amount, 0x2::balance::value<T0>(&arg0.reserved), arg0.position_size, v1, v2, v3, v7, 0x2::balance::split<T0>(&mut arg0.collateral, v6))
    }

    public(package) fun new_position_config(arg0: u64, arg1: u64, arg2: u64, arg3: u256, arg4: u128, arg5: u128, arg6: u128, arg7: u128) : PositionConfig {
        PositionConfig{
            max_leverage            : arg0,
            min_holding_duration    : arg1,
            max_reserved_multiplier : arg2,
            min_collateral_value    : sudo::decimal::from_raw(arg3),
            open_fee_bps            : sudo::rate::from_raw(arg4),
            decrease_fee_bps        : sudo::rate::from_raw(arg5),
            liquidation_threshold   : sudo::rate::from_raw(arg6),
            liquidation_bonus       : sudo::rate::from_raw(arg7),
        }
    }

    public(package) fun open_position<T0>(arg0: &PositionConfig, arg1: &sudo::agg_price::AggPrice, arg2: &sudo::agg_price::AggPrice, arg3: &mut 0x2::balance::Balance<T0>, arg4: &mut 0x2::balance::Balance<T0>, arg5: sudo::decimal::Decimal, arg6: u64, arg7: u64, arg8: sudo::rate::Rate, arg9: sudo::srate::SRate, arg10: u64) : (u64, 0x1::option::Option<OpenPositionResult<T0>>) {
        if (0x2::balance::value<T0>(arg4) == 0) {
            return (3, 0x1::option::none<OpenPositionResult<T0>>())
        };
        let v0 = sudo::agg_price::price_of(arg1);
        if (sudo::decimal::lt(&v0, &arg5)) {
            return (15, 0x1::option::none<OpenPositionResult<T0>>())
        };
        if (arg6 == 0) {
            return (5, 0x1::option::none<OpenPositionResult<T0>>())
        };
        if (0x2::balance::value<T0>(arg4) * arg0.max_reserved_multiplier < arg7) {
            return (14, 0x1::option::none<OpenPositionResult<T0>>())
        };
        let v1 = sudo::agg_price::coins_to_value(arg2, arg6);
        let v2 = sudo::agg_price::value_to_coins(arg1, sudo::decimal::mul_with_rate(v1, arg0.open_fee_bps));
        let v3 = sudo::decimal::ceil_u64(v2);
        if (v3 > 0x2::balance::value<T0>(arg4)) {
            return (7, 0x1::option::none<OpenPositionResult<T0>>())
        };
        let v4 = sudo::agg_price::coins_to_value(arg1, 0x2::balance::value<T0>(arg4) - v3);
        if (sudo::decimal::lt(&v4, &arg0.min_collateral_value)) {
            return (9, 0x1::option::none<OpenPositionResult<T0>>())
        };
        if (!check_leverage(arg0, v4, arg6, arg2)) {
            return (11, 0x1::option::none<OpenPositionResult<T0>>())
        };
        let v5 = Position<T0>{
            closed               : false,
            config               : *arg0,
            open_timestamp       : arg10,
            position_amount      : arg6,
            position_size        : v1,
            reserving_fee_amount : sudo::decimal::zero(),
            funding_fee_value    : sudo::sdecimal::zero(),
            last_reserving_rate  : arg8,
            last_funding_rate    : arg9,
            reserved             : 0x2::balance::split<T0>(arg3, arg7),
            collateral           : 0x2::balance::withdraw_all<T0>(arg4),
        };
        let v6 = OpenPositionResult<T0>{
            position        : v5,
            open_fee        : 0x2::balance::split<T0>(arg4, v3),
            open_fee_amount : v2,
        };
        (0, 0x1::option::some<OpenPositionResult<T0>>(v6))
    }

    public fun open_timestamp<T0>(arg0: &Position<T0>) : u64 {
        arg0.open_timestamp
    }

    public(package) fun pledge_in_position<T0>(arg0: &mut Position<T0>, arg1: 0x2::balance::Balance<T0>) {
        assert!(!arg0.closed, 1);
        assert!(0x2::balance::value<T0>(&arg1) > 0, 3);
        0x2::balance::join<T0>(&mut arg0.collateral, arg1);
    }

    public fun position_amount<T0>(arg0: &Position<T0>) : u64 {
        arg0.position_amount
    }

    public fun position_config<T0>(arg0: &Position<T0>) : &PositionConfig {
        &arg0.config
    }

    public fun position_size<T0>(arg0: &Position<T0>) : sudo::decimal::Decimal {
        arg0.position_size
    }

    public(package) fun redeem_from_position<T0>(arg0: &mut Position<T0>, arg1: &sudo::agg_price::AggPrice, arg2: &sudo::agg_price::AggPrice, arg3: bool, arg4: u64, arg5: sudo::rate::Rate, arg6: sudo::srate::SRate, arg7: u64) : 0x2::balance::Balance<T0> {
        assert!(!arg0.closed, 1);
        assert!(arg4 > 0 && arg4 < 0x2::balance::value<T0>(&arg0.collateral), 4);
        let mut v0 = compute_delta_size<T0>(arg0, arg2, arg3);
        assert!(check_holding_duration<T0>(arg0, &v0, arg7), 10);
        let v1 = compute_reserving_fee_amount<T0>(arg0, arg5);
        let v2 = compute_funding_fee_value<T0>(arg0, arg6);
        let v3 = v0;
        v0 = sudo::sdecimal::sub(v3, sudo::sdecimal::add_with_decimal(v2, sudo::agg_price::coins_to_value(arg1, sudo::decimal::ceil_u64(v1))));
        arg0.reserving_fee_amount = v1;
        arg0.funding_fee_value = v2;
        arg0.last_reserving_rate = arg5;
        arg0.last_funding_rate = arg6;
        assert!(0x2::balance::value<T0>(&arg0.collateral) * arg0.config.max_reserved_multiplier >= 0x2::balance::value<T0>(&arg0.reserved), 14);
        let v4 = sudo::agg_price::coins_to_value(arg1, 0x2::balance::value<T0>(&arg0.collateral));
        assert!(sudo::decimal::ge(&v4, &arg0.config.min_collateral_value), 9);
        assert!(check_leverage(&arg0.config, v4, arg0.position_amount, arg2), 11);
        assert!(!check_liquidation(&arg0.config, v4, &v0), 12);
        0x2::balance::split<T0>(&mut arg0.collateral, arg4)
    }

    public fun reserved_amount<T0>(arg0: &Position<T0>) : u64 {
        0x2::balance::value<T0>(&arg0.reserved)
    }

    public(package) fun unwrap_decrease_position_result<T0>(arg0: DecreasePositionResult<T0>) : (bool, bool, u64, u64, sudo::decimal::Decimal, sudo::decimal::Decimal, sudo::decimal::Decimal, sudo::decimal::Decimal, sudo::sdecimal::SDecimal, 0x2::balance::Balance<T0>, 0x2::balance::Balance<T0>) {
        let DecreasePositionResult<T0> {
            closed                    : v0,
            has_profit                : v1,
            settled_amount            : v2,
            decreased_reserved_amount : v3,
            decrease_size             : v4,
            reserving_fee_amount      : v5,
            decrease_fee_value        : v6,
            reserving_fee_value       : v7,
            funding_fee_value         : v8,
            to_vault                  : v9,
            to_trader                 : v10,
        } = arg0;
        (v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)
    }

    public(package) fun unwrap_open_position_result<T0>(arg0: OpenPositionResult<T0>) : (Position<T0>, 0x2::balance::Balance<T0>, sudo::decimal::Decimal) {
        let OpenPositionResult<T0> {
            position        : v0,
            open_fee        : v1,
            open_fee_amount : v2,
        } = arg0;
        (v0, v1, v2)
    }

    // decompiled from Move bytecode v6
}

