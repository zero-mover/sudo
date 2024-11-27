module sudo::orders {
    public struct OpenPositionOrder<phantom T0, phantom T1> has store {
        executed: bool,
        created_at: u64,
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: sudo::agg_price::AggPrice,
        collateral_price_threshold: sudo::decimal::Decimal,
        position_config: sudo::position::PositionConfig,
        collateral: 0x2::balance::Balance<T0>,
        fee: 0x2::balance::Balance<T1>,
    }

    public struct OpenPositionOrderV1_1<phantom T0, phantom T1> has store {
        executed: bool,
        created_at: u64,
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: sudo::decimal::Decimal,
        collateral_price_threshold: sudo::decimal::Decimal,
        position_config: sudo::position::PositionConfig,
        collateral: 0x2::balance::Balance<T0>,
        fee: 0x2::balance::Balance<T1>,
    }

    public struct DecreasePositionOrder<phantom T0> has store {
        executed: bool,
        created_at: u64,
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: sudo::agg_price::AggPrice,
        collateral_price_threshold: sudo::decimal::Decimal,
        fee: 0x2::balance::Balance<T0>,
    }

    public struct DecreasePositionOrderV1_1<phantom T0> has store {
        executed: bool,
        created_at: u64,
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: sudo::decimal::Decimal,
        collateral_price_threshold: sudo::decimal::Decimal,
        fee: 0x2::balance::Balance<T0>,
    }

    public struct CreateOpenPositionOrderEvent has copy, drop {
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: sudo::decimal::Decimal,
        collateral_price_threshold: sudo::decimal::Decimal,
        position_config: sudo::position::PositionConfig,
        collateral_amount: u64,
        fee_amount: u64,
    }

    public struct CreateDecreasePositionOrderEvent has copy, drop {
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: sudo::decimal::Decimal,
        collateral_price_threshold: sudo::decimal::Decimal,
        fee_amount: u64,
    }

    public(package) fun destroy_decrease_position_order<T0>(arg0: DecreasePositionOrder<T0>) : 0x2::balance::Balance<T0> {
        let DecreasePositionOrder<T0> {
            executed                   : _,
            created_at                 : _,
            take_profit                : _,
            decrease_amount            : _,
            limited_index_price        : _,
            collateral_price_threshold : _,
            fee                        : v6,
        } = arg0;
        v6
    }

    public(package) fun destroy_decrease_position_order_v1_1<T0>(arg0: DecreasePositionOrderV1_1<T0>) : 0x2::balance::Balance<T0> {
        let DecreasePositionOrderV1_1<T0> {
            executed                   : _,
            created_at                 : _,
            take_profit                : _,
            decrease_amount            : _,
            limited_index_price        : _,
            collateral_price_threshold : _,
            fee                        : v6,
        } = arg0;
        v6
    }

    public(package) fun destroy_open_position_order<T0, T1>(arg0: OpenPositionOrder<T0, T1>) : (0x2::balance::Balance<T0>, 0x2::balance::Balance<T1>) {
        let OpenPositionOrder<T0, T1> {
            executed                   : _,
            created_at                 : _,
            open_amount                : _,
            reserve_amount             : _,
            limited_index_price        : _,
            collateral_price_threshold : _,
            position_config            : _,
            collateral                 : v7,
            fee                        : v8,
        } = arg0;
        (v7, v8)
    }

    public(package) fun destroy_open_position_order_v1_1<T0, T1>(arg0: OpenPositionOrderV1_1<T0, T1>) : (0x2::balance::Balance<T0>, 0x2::balance::Balance<T1>) {
        let OpenPositionOrderV1_1<T0, T1> {
            executed                   : _,
            created_at                 : _,
            open_amount                : _,
            reserve_amount             : _,
            limited_index_price        : _,
            collateral_price_threshold : _,
            position_config            : _,
            collateral                 : v7,
            fee                        : v8,
        } = arg0;
        (v7, v8)
    }

    public(package) fun execute_decrease_position_order<T0, T1>(arg0: &mut DecreasePositionOrder<T1>, arg1: &mut sudo::pool::Vault<T0>, arg2: &mut sudo::pool::Symbol, arg3: &mut sudo::position::Position<T0>, arg4: &sudo::model::ReservingFeeModel, arg5: &sudo::model::FundingFeeModel, arg6: &sudo::agg_price::AggPrice, arg7: &sudo::agg_price::AggPrice, arg8: sudo::rate::Rate, arg9: bool, arg10: sudo::decimal::Decimal, arg11: u64) : (u64, 0x1::option::Option<sudo::pool::DecreasePositionResult<T0>>, 0x1::option::Option<sudo::pool::DecreasePositionFailedEvent>, 0x2::balance::Balance<T1>) {
        assert!(!arg0.executed, 1);
        if (arg9 && arg0.take_profit || !arg9 && !arg0.take_profit) {
            let v0 = sudo::agg_price::price_of(arg7);
            let v1 = sudo::agg_price::price_of(&arg0.limited_index_price);
            assert!(sudo::decimal::ge(&v0, &v1), 2);
        } else {
            let mut v2 = sudo::agg_price::price_of(arg7);
            let v3 = sudo::agg_price::price_of(&arg0.limited_index_price);
            assert!(sudo::decimal::le(&v2, &v3), 2);
        };
        arg0.executed = true;
        let (v4, v5, v6) = sudo::pool::decrease_position<T0>(arg1, arg2, arg3, arg4, arg5, arg6, &arg0.limited_index_price, arg0.collateral_price_threshold, arg8, arg9, arg0.decrease_amount, arg10, arg11);
        (v4, v5, v6, 0x2::balance::withdraw_all<T1>(&mut arg0.fee))
    }

    public(package) fun execute_decrease_position_order_v1_1<T0, T1>(arg0: &mut DecreasePositionOrderV1_1<T1>, arg1: &mut sudo::pool::Vault<T0>, arg2: &mut sudo::pool::Symbol, arg3: &mut sudo::position::Position<T0>, arg4: &sudo::model::ReservingFeeModel, arg5: &sudo::model::FundingFeeModel, arg6: &sudo::agg_price::AggPrice, arg7: &sudo::agg_price::AggPrice, arg8: sudo::rate::Rate, arg9: bool, arg10: sudo::decimal::Decimal, arg11: u64) : (u64, 0x1::option::Option<sudo::pool::DecreasePositionResult<T0>>, 0x1::option::Option<sudo::pool::DecreasePositionFailedEvent>, 0x2::balance::Balance<T1>) {
        assert!(!arg0.executed, 1);
        if (arg9 && arg0.take_profit || !arg9 && !arg0.take_profit) {
            let v0 = sudo::agg_price::price_of(arg7);
            assert!(sudo::decimal::ge(&v0, &arg0.limited_index_price), 2);
        } else {
            let v1 = sudo::agg_price::price_of(arg7);
            assert!(sudo::decimal::le(&v1, &arg0.limited_index_price), 2);
        };
        arg0.executed = true;
        let mut v2 = sudo::agg_price::from_price(sudo::pool::symbol_price_config(arg2), arg0.limited_index_price);
        let (v3, v4, v5) = sudo::pool::decrease_position<T0>(arg1, arg2, arg3, arg4, arg5, arg6, &v2, arg0.collateral_price_threshold, arg8, arg9, arg0.decrease_amount, arg10, arg11);
        (v3, v4, v5, 0x2::balance::withdraw_all<T1>(&mut arg0.fee))
    }

    public(package) fun execute_open_position_order<T0, T1>(arg0: &mut OpenPositionOrder<T0, T1>, arg1: &mut sudo::pool::Vault<T0>, arg2: &mut sudo::pool::Symbol, arg3: &sudo::model::ReservingFeeModel, arg4: &sudo::model::FundingFeeModel, arg5: &sudo::agg_price::AggPrice, arg6: &sudo::agg_price::AggPrice, arg7: sudo::rate::Rate, arg8: bool, arg9: sudo::decimal::Decimal, arg10: u64) : (u64, 0x1::option::Option<sudo::pool::OpenPositionResult<T0>>, 0x1::option::Option<sudo::pool::OpenPositionFailedEvent>, 0x2::balance::Balance<T1>) {
        assert!(!arg0.executed, 1);
        if (arg8) {
            let v0 = sudo::agg_price::price_of(arg6);
            let v1 = sudo::agg_price::price_of(&arg0.limited_index_price);
            assert!(sudo::decimal::le(&v0, &v1), 2);
        } else {
            let v2 = sudo::agg_price::price_of(arg6);
            let v3 = sudo::agg_price::price_of(&arg0.limited_index_price);
            assert!(sudo::decimal::ge(&v2, &v3), 2);
        };
        arg0.executed = true;
        let (v4, v5, v6) = sudo::pool::open_position<T0>(arg1, arg2, arg3, arg4, &arg0.position_config, arg5, &arg0.limited_index_price, &mut arg0.collateral, arg0.collateral_price_threshold, arg7, arg8, arg0.open_amount, arg0.reserve_amount, arg9, arg10);
        (v4, v5, v6, 0x2::balance::withdraw_all<T1>(&mut arg0.fee))
    }

    public(package) fun execute_open_position_order_v1_1<T0, T1>(arg0: &mut OpenPositionOrderV1_1<T0, T1>, arg1: &mut sudo::pool::Vault<T0>, arg2: &mut sudo::pool::Symbol, arg3: &sudo::model::ReservingFeeModel, arg4: &sudo::model::FundingFeeModel, arg5: &sudo::agg_price::AggPrice, arg6: &sudo::agg_price::AggPrice, arg7: sudo::rate::Rate, arg8: bool, arg9: sudo::decimal::Decimal, arg10: u64) : (u64, 0x1::option::Option<sudo::pool::OpenPositionResult<T0>>, 0x1::option::Option<sudo::pool::OpenPositionFailedEvent>, 0x2::balance::Balance<T1>) {
        assert!(!arg0.executed, 1);
        if (arg8) {
            let v0 = sudo::agg_price::price_of(arg6);
            assert!(sudo::decimal::le(&v0, &arg0.limited_index_price), 2);
        } else {
            let v1 = sudo::agg_price::price_of(arg6);
            assert!(sudo::decimal::ge(&v1, &arg0.limited_index_price), 2);
        };
        arg0.executed = true;
        let v2 = sudo::agg_price::from_price(sudo::pool::symbol_price_config(arg2), arg0.limited_index_price);
        let (v3, v4, v5) = sudo::pool::open_position<T0>(arg1, arg2, arg3, arg4, &arg0.position_config, arg5, &v2, &mut arg0.collateral, arg0.collateral_price_threshold, arg7, arg8, arg0.open_amount, arg0.reserve_amount, arg9, arg10);
        (v3, v4, v5, 0x2::balance::withdraw_all<T1>(&mut arg0.fee))
    }

    public(package) fun new_decrease_position_order<T0>(arg0: u64, arg1: bool, arg2: u64, arg3: sudo::agg_price::AggPrice, arg4: sudo::decimal::Decimal, arg5: 0x2::balance::Balance<T0>) : (DecreasePositionOrder<T0>, CreateDecreasePositionOrderEvent) {
        let v0 = CreateDecreasePositionOrderEvent{
            take_profit                : arg1,
            decrease_amount            : arg2,
            limited_index_price        : sudo::agg_price::price_of(&arg3),
            collateral_price_threshold : arg4,
            fee_amount                 : 0x2::balance::value<T0>(&arg5),
        };
        let v1 = DecreasePositionOrder<T0>{
            executed                   : false,
            created_at                 : arg0,
            take_profit                : arg1,
            decrease_amount            : arg2,
            limited_index_price        : arg3,
            collateral_price_threshold : arg4,
            fee                        : arg5,
        };
        (v1, v0)
    }

    public(package) fun new_decrease_position_order_v1_1<T0>(arg0: u64, arg1: bool, arg2: u64, arg3: sudo::decimal::Decimal, arg4: sudo::decimal::Decimal, arg5: 0x2::balance::Balance<T0>) : (DecreasePositionOrderV1_1<T0>, CreateDecreasePositionOrderEvent) {
        let v0 = CreateDecreasePositionOrderEvent{
            take_profit                : arg1,
            decrease_amount            : arg2,
            limited_index_price        : arg3,
            collateral_price_threshold : arg4,
            fee_amount                 : 0x2::balance::value<T0>(&arg5),
        };
        let v1 = DecreasePositionOrderV1_1<T0>{
            executed                   : false,
            created_at                 : arg0,
            take_profit                : arg1,
            decrease_amount            : arg2,
            limited_index_price        : arg3,
            collateral_price_threshold : arg4,
            fee                        : arg5,
        };
        (v1, v0)
    }

    public(package) fun new_open_position_order<T0, T1>(arg0: u64, arg1: u64, arg2: u64, arg3: sudo::agg_price::AggPrice, arg4: sudo::decimal::Decimal, arg5: sudo::position::PositionConfig, arg6: 0x2::balance::Balance<T0>, arg7: 0x2::balance::Balance<T1>) : (OpenPositionOrder<T0, T1>, CreateOpenPositionOrderEvent) {
        let v0 = CreateOpenPositionOrderEvent{
            open_amount                : arg1,
            reserve_amount             : arg2,
            limited_index_price        : sudo::agg_price::price_of(&arg3),
            collateral_price_threshold : arg4,
            position_config            : arg5,
            collateral_amount          : 0x2::balance::value<T0>(&arg6),
            fee_amount                 : 0x2::balance::value<T1>(&arg7),
        };
        let v1 = OpenPositionOrder<T0, T1>{
            executed                   : false,
            created_at                 : arg0,
            open_amount                : arg1,
            reserve_amount             : arg2,
            limited_index_price        : arg3,
            collateral_price_threshold : arg4,
            position_config            : arg5,
            collateral                 : arg6,
            fee                        : arg7,
        };
        (v1, v0)
    }

    public(package) fun new_open_position_order_v1_1<T0, T1>(arg0: u64, arg1: u64, arg2: u64, arg3: sudo::decimal::Decimal, arg4: sudo::decimal::Decimal, arg5: sudo::position::PositionConfig, arg6: 0x2::balance::Balance<T0>, arg7: 0x2::balance::Balance<T1>) : (OpenPositionOrderV1_1<T0, T1>, CreateOpenPositionOrderEvent) {
        let v0 = CreateOpenPositionOrderEvent{
            open_amount                : arg1,
            reserve_amount             : arg2,
            limited_index_price        : arg3,
            collateral_price_threshold : arg4,
            position_config            : arg5,
            collateral_amount          : 0x2::balance::value<T0>(&arg6),
            fee_amount                 : 0x2::balance::value<T1>(&arg7),
        };
        let v1 = OpenPositionOrderV1_1<T0, T1>{
            executed                   : false,
            created_at                 : arg0,
            open_amount                : arg1,
            reserve_amount             : arg2,
            limited_index_price        : arg3,
            collateral_price_threshold : arg4,
            position_config            : arg5,
            collateral                 : arg6,
            fee                        : arg7,
        };
        (v1, v0)
    }

    // decompiled from Move bytecode v6
}

