module sudo::pool {
    public struct Vault<phantom T0> has store {
        enabled: bool,
        weight: sudo::decimal::Decimal,
        reserving_fee_model: 0x2::object::ID,
        price_config: sudo::agg_price::AggPriceConfig,
        last_update: u64,
        liquidity: 0x2::balance::Balance<T0>,
        reserved_amount: u64,
        unrealised_reserving_fee_amount: sudo::decimal::Decimal,
        acc_reserving_rate: sudo::rate::Rate,
    }

    public struct Symbol has store {
        open_enabled: bool,
        decrease_enabled: bool,
        liquidate_enabled: bool,
        supported_collaterals: 0x2::vec_set::VecSet<0x1::type_name::TypeName>,
        funding_fee_model: 0x2::object::ID,
        price_config: sudo::agg_price::AggPriceConfig,
        last_update: u64,
        opening_amount: u64,
        opening_size: sudo::decimal::Decimal,
        realised_pnl: sudo::sdecimal::SDecimal,
        unrealised_funding_fee_value: sudo::sdecimal::SDecimal,
        acc_funding_rate: sudo::srate::SRate,
    }

    public struct OpenPositionResult<phantom T0> {
        position: sudo::position::Position<T0>,
        rebate: 0x2::balance::Balance<T0>,
        event: OpenPositionSuccessEvent,
    }

    public struct DecreasePositionResult<phantom T0> {
        to_trader: 0x2::balance::Balance<T0>,
        rebate: 0x2::balance::Balance<T0>,
        event: DecreasePositionSuccessEvent,
    }

    public struct OpenPositionSuccessEvent has copy, drop {
        position_config: sudo::position::PositionConfig,
        collateral_price: sudo::decimal::Decimal,
        index_price: sudo::decimal::Decimal,
        open_amount: u64,
        open_fee_amount: u64,
        reserve_amount: u64,
        collateral_amount: u64,
        rebate_amount: u64,
    }

    public struct OpenPositionFailedEvent has copy, drop {
        position_config: sudo::position::PositionConfig,
        collateral_price: sudo::decimal::Decimal,
        index_price: sudo::decimal::Decimal,
        open_amount: u64,
        collateral_amount: u64,
        code: u64,
    }

    public struct DecreasePositionSuccessEvent has copy, drop {
        collateral_price: sudo::decimal::Decimal,
        index_price: sudo::decimal::Decimal,
        decrease_amount: u64,
        decrease_fee_value: sudo::decimal::Decimal,
        reserving_fee_value: sudo::decimal::Decimal,
        funding_fee_value: sudo::sdecimal::SDecimal,
        delta_realised_pnl: sudo::sdecimal::SDecimal,
        closed: bool,
        has_profit: bool,
        settled_amount: u64,
        rebate_amount: u64,
    }

    public struct DecreasePositionFailedEvent has copy, drop {
        collateral_price: sudo::decimal::Decimal,
        index_price: sudo::decimal::Decimal,
        decrease_amount: u64,
        code: u64,
    }

    public struct DecreaseReservedFromPositionEvent has copy, drop {
        decrease_amount: u64,
    }

    public struct PledgeInPositionEvent has copy, drop {
        pledge_amount: u64,
    }

    public struct RedeemFromPositionEvent has copy, drop {
        collateral_price: sudo::decimal::Decimal,
        index_price: sudo::decimal::Decimal,
        redeem_amount: u64,
    }

    public struct LiquidatePositionEvent has copy, drop {
        liquidator: address,
        collateral_price: sudo::decimal::Decimal,
        index_price: sudo::decimal::Decimal,
        reserving_fee_value: sudo::decimal::Decimal,
        funding_fee_value: sudo::sdecimal::SDecimal,
        delta_realised_pnl: sudo::sdecimal::SDecimal,
        loss_amount: u64,
        liquidator_bonus_amount: u64,
    }

    public struct LiquidatePositionEventV1_1 has copy, drop {
        liquidator: address,
        collateral_price: sudo::decimal::Decimal,
        index_price: sudo::decimal::Decimal,
        position_size: sudo::decimal::Decimal,
        reserving_fee_value: sudo::decimal::Decimal,
        funding_fee_value: sudo::sdecimal::SDecimal,
        delta_realised_pnl: sudo::sdecimal::SDecimal,
        loss_amount: u64,
        liquidator_bonus_amount: u64,
    }

    public fun compute_rebase_fee_rate(arg0: &sudo::model::RebaseFeeModel, arg1: bool, arg2: sudo::decimal::Decimal, arg3: sudo::decimal::Decimal, arg4: sudo::decimal::Decimal, arg5: sudo::decimal::Decimal) : sudo::rate::Rate {
        if (sudo::decimal::eq(&arg2, &arg3)) {
            sudo::rate::zero()
        } else {
            sudo::model::compute_rebase_fee_rate(arg0, arg1, sudo::decimal::to_rate(sudo::decimal::div(arg2, arg3)), sudo::decimal::to_rate(sudo::decimal::div(arg4, arg5)))
        }
    }

    public(package) fun add_collateral_to_symbol<T0>(arg0: &mut Symbol) {
        0x2::vec_set::insert<0x1::type_name::TypeName>(&mut arg0.supported_collaterals, 0x1::type_name::get<T0>());
    }

    public(package) fun decrease_position<T0>(arg0: &mut Vault<T0>, arg1: &mut Symbol, arg2: &mut sudo::position::Position<T0>, arg3: &sudo::model::ReservingFeeModel, arg4: &sudo::model::FundingFeeModel, arg5: &sudo::agg_price::AggPrice, arg6: &sudo::agg_price::AggPrice, arg7: sudo::decimal::Decimal, arg8: sudo::rate::Rate, arg9: bool, arg10: u64, arg11: sudo::decimal::Decimal, arg12: u64) : (u64, 0x1::option::Option<DecreasePositionResult<T0>>, 0x1::option::Option<DecreasePositionFailedEvent>) {
        assert!(arg0.enabled, 1);
        assert!(arg1.decrease_enabled, 6);
        assert!(0x2::object::id<sudo::model::ReservingFeeModel>(arg3) == arg0.reserving_fee_model, 13);
        assert!(0x2::object::id<sudo::model::FundingFeeModel>(arg4) == arg1.funding_fee_model, 14);
        refresh_vault<T0>(arg0, arg3, arg12);
        let v0 = symbol_delta_size(arg1, arg6, arg9);
        refresh_symbol(arg1, arg4, v0, arg11, arg12);
        let (v1, v2) = sudo::position::decrease_position<T0>(arg2, arg5, arg6, arg7, arg9, arg10, arg0.acc_reserving_rate, arg1.acc_funding_rate, arg12);
        if (v1 > 0) {
            0x1::option::destroy_none<sudo::position::DecreasePositionResult<T0>>(v2);
            let v3 = DecreasePositionFailedEvent{
                collateral_price : sudo::agg_price::price_of(arg5),
                index_price      : sudo::agg_price::price_of(arg6),
                decrease_amount  : arg10,
                code             : v1,
            };
            return (v1, 0x1::option::none<DecreasePositionResult<T0>>(), 0x1::option::some<DecreasePositionFailedEvent>(v3))
        };
        let (v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14) = sudo::position::unwrap_decrease_position_result<T0>(0x1::option::destroy_some<sudo::position::DecreasePositionResult<T0>>(v2));
        let v15 = sudo::decimal::mul_with_rate(v10, arg8);
        let v16 = sudo::decimal::floor_u64(sudo::agg_price::value_to_coins(arg5, v15));
        arg0.reserved_amount = arg0.reserved_amount - v7;
        arg0.unrealised_reserving_fee_amount = sudo::decimal::sub(arg0.unrealised_reserving_fee_amount, v9);
        assert!(0x2::balance::join<T0>(&mut arg0.liquidity, v13) > v16, 3);
        arg1.opening_size = sudo::decimal::sub(arg1.opening_size, v8);
        arg1.opening_amount = arg1.opening_amount - arg10;
        arg1.unrealised_funding_fee_value = sudo::sdecimal::sub(arg1.unrealised_funding_fee_value, v12);
        let v17 = sudo::sdecimal::sub_with_decimal(sudo::sdecimal::from_decimal(!v5, sudo::agg_price::coins_to_value(arg5, v6)), sudo::decimal::add(sudo::decimal::sub(v10, v15), v11));
        arg1.realised_pnl = sudo::sdecimal::add(arg1.realised_pnl, v17);
        let v18 = DecreasePositionSuccessEvent{
            collateral_price    : sudo::agg_price::price_of(arg5),
            index_price         : sudo::agg_price::price_of(arg6),
            decrease_amount     : arg10,
            decrease_fee_value  : v10,
            reserving_fee_value : v11,
            funding_fee_value   : v12,
            delta_realised_pnl  : v17,
            closed              : v4,
            has_profit          : v5,
            settled_amount      : v6,
            rebate_amount       : v16,
        };
        let v19 = DecreasePositionResult<T0>{
            to_trader : v14,
            rebate    : 0x2::balance::split<T0>(&mut arg0.liquidity, v16),
            event     : v18,
        };
        (v1, 0x1::option::some<DecreasePositionResult<T0>>(v19), 0x1::option::none<DecreasePositionFailedEvent>())
    }

    public(package) fun decrease_reserved_from_position<T0>(arg0: &mut Vault<T0>, arg1: &mut sudo::position::Position<T0>, arg2: &sudo::model::ReservingFeeModel, arg3: u64, arg4: u64) : DecreaseReservedFromPositionEvent {
        assert!(0x2::object::id<sudo::model::ReservingFeeModel>(arg2) == arg0.reserving_fee_model, 13);
        refresh_vault<T0>(arg0, arg2, arg4);
        arg0.reserved_amount = arg0.reserved_amount - arg3;
        0x2::balance::join<T0>(&mut arg0.liquidity, sudo::position::decrease_reserved_from_position<T0>(arg1, arg3, arg0.acc_reserving_rate));
        DecreaseReservedFromPositionEvent{decrease_amount: arg3}
    }

    public(package) fun deposit<T0>(arg0: &mut Vault<T0>, arg1: &sudo::model::RebaseFeeModel, arg2: &sudo::agg_price::AggPrice, arg3: 0x2::balance::Balance<T0>, arg4: u64, arg5: u64, arg6: sudo::decimal::Decimal, arg7: sudo::decimal::Decimal, arg8: sudo::decimal::Decimal, arg9: sudo::decimal::Decimal) : (u64, sudo::decimal::Decimal) {
        assert!(arg0.enabled, 1);
        let v0 = 0x2::balance::value<T0>(&arg3);
        assert!(v0 > 0, 9);
        let v1 = sudo::agg_price::coins_to_value(arg2, v0);
        let v2 = sudo::decimal::mul_with_rate(v1, compute_rebase_fee_rate(arg1, true, sudo::decimal::add(arg7, v1), sudo::decimal::add(arg8, v1), arg0.weight, arg9));
        0x2::balance::join<T0>(&mut arg0.liquidity, arg3);
        let mut v3 = if (arg5 == 0) {
            assert!(sudo::decimal::is_zero(&arg6), 11);
            truncate_decimal(sudo::decimal::sub(v1, v2))
        } else {
            assert!(!sudo::decimal::is_zero(&arg6), 11);
            sudo::decimal::floor_u64(sudo::decimal::mul_with_rate(sudo::decimal::from_u64(arg5), sudo::decimal::to_rate(sudo::decimal::div(sudo::decimal::sub(v1, v2), arg6))))
        };
        assert!(v3 >= arg4, 12);
        (v3, v2)
    }

    public(package) fun liquidate_position<T0>(arg0: &mut Vault<T0>, arg1: &mut Symbol, arg2: &mut sudo::position::Position<T0>, arg3: &sudo::model::ReservingFeeModel, arg4: &sudo::model::FundingFeeModel, arg5: &sudo::agg_price::AggPrice, arg6: &sudo::agg_price::AggPrice, arg7: bool, arg8: sudo::decimal::Decimal, arg9: u64, arg10: address) : (0x2::balance::Balance<T0>, LiquidatePositionEvent) {
        assert!(arg0.enabled, 1);
        assert!(arg1.liquidate_enabled, 7);
        assert!(0x2::object::id<sudo::model::ReservingFeeModel>(arg3) == arg0.reserving_fee_model, 13);
        assert!(0x2::object::id<sudo::model::FundingFeeModel>(arg4) == arg1.funding_fee_model, 14);
        refresh_vault<T0>(arg0, arg3, arg9);
        let v0 = symbol_delta_size(arg1, arg6, arg7);
        refresh_symbol(arg1, arg4, v0, arg8, arg9);
        let (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) = sudo::position::liquidate_position<T0>(arg2, arg5, arg6, arg7, arg0.acc_reserving_rate, arg1.acc_funding_rate);
        arg0.reserved_amount = arg0.reserved_amount - v4;
        arg0.unrealised_reserving_fee_amount = sudo::decimal::sub(arg0.unrealised_reserving_fee_amount, v6);
        0x2::balance::join<T0>(&mut arg0.liquidity, v9);
        arg1.opening_size = sudo::decimal::sub(arg1.opening_size, v5);
        arg1.opening_amount = arg1.opening_amount - v3;
        arg1.unrealised_funding_fee_value = sudo::sdecimal::sub(arg1.unrealised_funding_fee_value, v8);
        let v11 = sudo::sdecimal::sub_with_decimal(sudo::sdecimal::from_decimal(true, sudo::agg_price::coins_to_value(arg5, v2)), v7);
        arg1.realised_pnl = sudo::sdecimal::add(arg1.realised_pnl, v11);
        let v12 = LiquidatePositionEvent{
            liquidator              : arg10,
            collateral_price        : sudo::agg_price::price_of(arg5),
            index_price             : sudo::agg_price::price_of(arg6),
            reserving_fee_value     : v7,
            funding_fee_value       : v8,
            delta_realised_pnl      : v11,
            loss_amount             : v2,
            liquidator_bonus_amount : v1,
        };
        (v10, v12)
    }

    public(package) fun liquidate_position_v1_1<T0>(arg0: &mut Vault<T0>, arg1: &mut Symbol, arg2: &mut sudo::position::Position<T0>, arg3: &sudo::model::ReservingFeeModel, arg4: &sudo::model::FundingFeeModel, arg5: &sudo::agg_price::AggPrice, arg6: &sudo::agg_price::AggPrice, arg7: bool, arg8: sudo::decimal::Decimal, arg9: u64, arg10: address) : (0x2::balance::Balance<T0>, LiquidatePositionEventV1_1) {
        assert!(arg0.enabled, 1);
        assert!(arg1.liquidate_enabled, 7);
        assert!(0x2::object::id<sudo::model::ReservingFeeModel>(arg3) == arg0.reserving_fee_model, 13);
        assert!(0x2::object::id<sudo::model::FundingFeeModel>(arg4) == arg1.funding_fee_model, 14);
        refresh_vault<T0>(arg0, arg3, arg9);
        let v0 = symbol_delta_size(arg1, arg6, arg7);
        refresh_symbol(arg1, arg4, v0, arg8, arg9);
        let (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10) = sudo::position::liquidate_position<T0>(arg2, arg5, arg6, arg7, arg0.acc_reserving_rate, arg1.acc_funding_rate);
        arg0.reserved_amount = arg0.reserved_amount - v4;
        arg0.unrealised_reserving_fee_amount = sudo::decimal::sub(arg0.unrealised_reserving_fee_amount, v6);
        0x2::balance::join<T0>(&mut arg0.liquidity, v9);
        arg1.opening_size = sudo::decimal::sub(arg1.opening_size, v5);
        arg1.opening_amount = arg1.opening_amount - v3;
        arg1.unrealised_funding_fee_value = sudo::sdecimal::sub(arg1.unrealised_funding_fee_value, v8);
        let v11 = sudo::sdecimal::sub_with_decimal(sudo::sdecimal::from_decimal(true, sudo::agg_price::coins_to_value(arg5, v2)), v7);
        arg1.realised_pnl = sudo::sdecimal::add(arg1.realised_pnl, v11);
        let v12 = LiquidatePositionEventV1_1{
            liquidator              : arg10,
            collateral_price        : sudo::agg_price::price_of(arg5),
            index_price             : sudo::agg_price::price_of(arg6),
            position_size           : v5,
            reserving_fee_value     : v7,
            funding_fee_value       : v8,
            delta_realised_pnl      : v11,
            loss_amount             : v2,
            liquidator_bonus_amount : v1,
        };
        (v10, v12)
    }

    public(package) fun mut_symbol_price_config(arg0: &mut Symbol) : &mut sudo::agg_price::AggPriceConfig {
        &mut arg0.price_config
    }

    public(package) fun mut_vault_price_config<T0>(arg0: &mut Vault<T0>) : &mut sudo::agg_price::AggPriceConfig {
        &mut arg0.price_config
    }

    public(package) fun new_symbol(arg0: 0x2::object::ID, arg1: sudo::agg_price::AggPriceConfig) : Symbol {
        Symbol{
            open_enabled                 : true,
            decrease_enabled             : true,
            liquidate_enabled            : true,
            supported_collaterals        : 0x2::vec_set::empty<0x1::type_name::TypeName>(),
            funding_fee_model            : arg0,
            price_config                 : arg1,
            last_update                  : 0,
            opening_amount               : 0,
            opening_size                 : sudo::decimal::zero(),
            realised_pnl                 : sudo::sdecimal::zero(),
            unrealised_funding_fee_value : sudo::sdecimal::zero(),
            acc_funding_rate             : sudo::srate::zero(),
        }
    }

    public(package) fun new_vault<T0>(arg0: u256, arg1: 0x2::object::ID, arg2: sudo::agg_price::AggPriceConfig) : Vault<T0> {
        Vault<T0>{
            enabled                         : true,
            weight                          : sudo::decimal::from_raw(arg0),
            reserving_fee_model             : arg1,
            price_config                    : arg2,
            last_update                     : 0,
            liquidity                       : 0x2::balance::zero<T0>(),
            reserved_amount                 : 0,
            unrealised_reserving_fee_amount : sudo::decimal::zero(),
            acc_reserving_rate              : sudo::rate::zero(),
        }
    }

    public(package) fun open_position<T0>(arg0: &mut Vault<T0>, arg1: &mut Symbol, arg2: &sudo::model::ReservingFeeModel, arg3: &sudo::model::FundingFeeModel, arg4: &sudo::position::PositionConfig, arg5: &sudo::agg_price::AggPrice, arg6: &sudo::agg_price::AggPrice, arg7: &mut 0x2::balance::Balance<T0>, arg8: sudo::decimal::Decimal, arg9: sudo::rate::Rate, arg10: bool, arg11: u64, arg12: u64, arg13: sudo::decimal::Decimal, arg14: u64) : (u64, 0x1::option::Option<OpenPositionResult<T0>>, 0x1::option::Option<OpenPositionFailedEvent>) {
        assert!(arg0.enabled, 1);
        assert!(arg1.open_enabled, 5);
        assert!(0x2::object::id<sudo::model::ReservingFeeModel>(arg2) == arg0.reserving_fee_model, 13);
        assert!(0x2::object::id<sudo::model::FundingFeeModel>(arg3) == arg1.funding_fee_model, 14);
        let v0 = 0x1::type_name::get<T0>();
        assert!(0x2::vec_set::contains<0x1::type_name::TypeName>(&arg1.supported_collaterals, &v0), 4);
        assert!(0x2::balance::value<T0>(&arg0.liquidity) > arg12, 3);
        refresh_vault<T0>(arg0, arg2, arg14);
        let v1 = symbol_delta_size(arg1, arg6, arg10);
        refresh_symbol(arg1, arg3, v1, arg13, arg14);
        let (v2, v3) = sudo::position::open_position<T0>(arg4, arg5, arg6, &mut arg0.liquidity, arg7, arg8, arg11, arg12, arg0.acc_reserving_rate, arg1.acc_funding_rate, arg14);
        if (v2 > 0) {
            0x1::option::destroy_none<sudo::position::OpenPositionResult<T0>>(v3);
            let v4 = OpenPositionFailedEvent{
                position_config   : *arg4,
                collateral_price  : sudo::agg_price::price_of(arg5),
                index_price       : sudo::agg_price::price_of(arg6),
                open_amount       : arg11,
                collateral_amount : 0x2::balance::value<T0>(arg7),
                code              : v2,
            };
            return (v2, 0x1::option::none<OpenPositionResult<T0>>(), 0x1::option::some<OpenPositionFailedEvent>(v4))
        };
        let (v5, v6, v7) = sudo::position::unwrap_open_position_result<T0>(0x1::option::destroy_some<sudo::position::OpenPositionResult<T0>>(v3));
        let v8 = v6;
        let v9 = v5;
        let v10 = 0x2::balance::value<T0>(&v8);
        let v11 = sudo::decimal::floor_u64(sudo::decimal::mul_with_rate(v7, arg9));
        arg0.reserved_amount = arg0.reserved_amount + arg12;
        assert!(0x2::balance::join<T0>(&mut arg0.liquidity, v8) > v11, 3);
        arg1.opening_size = sudo::decimal::add(arg1.opening_size, sudo::position::position_size<T0>(&v9));
        arg1.opening_amount = arg1.opening_amount + arg11;
        let v12 = sudo::position::collateral_amount<T0>(&v9);
        let v13 = OpenPositionSuccessEvent{
            position_config   : *arg4,
            collateral_price  : sudo::agg_price::price_of(arg5),
            index_price       : sudo::agg_price::price_of(arg6),
            open_amount       : arg11,
            open_fee_amount   : v10,
            reserve_amount    : arg12,
            collateral_amount : v12,
            rebate_amount     : v11,
        };
        let v14 = OpenPositionResult<T0>{
            position : v9,
            rebate   : 0x2::balance::split<T0>(&mut arg0.liquidity, v11),
            event    : v13,
        };
        (v2, 0x1::option::some<OpenPositionResult<T0>>(v14), 0x1::option::none<OpenPositionFailedEvent>())
    }

    public(package) fun pledge_in_position<T0>(arg0: &mut sudo::position::Position<T0>, arg1: 0x2::balance::Balance<T0>) : PledgeInPositionEvent {
        let v0 = 0x2::balance::value<T0>(&arg1);
        sudo::position::pledge_in_position<T0>(arg0, arg1);
        PledgeInPositionEvent{pledge_amount: v0}
    }

    public(package) fun redeem_from_position<T0>(arg0: &mut Vault<T0>, arg1: &mut Symbol, arg2: &mut sudo::position::Position<T0>, arg3: &sudo::model::ReservingFeeModel, arg4: &sudo::model::FundingFeeModel, arg5: &sudo::agg_price::AggPrice, arg6: &sudo::agg_price::AggPrice, arg7: bool, arg8: u64, arg9: sudo::decimal::Decimal, arg10: u64) : (0x2::balance::Balance<T0>, RedeemFromPositionEvent) {
        assert!(0x2::object::id<sudo::model::ReservingFeeModel>(arg3) == arg0.reserving_fee_model, 13);
        assert!(0x2::object::id<sudo::model::FundingFeeModel>(arg4) == arg1.funding_fee_model, 14);
        refresh_vault<T0>(arg0, arg3, arg10);
        let v0 = symbol_delta_size(arg1, arg6, arg7);
        refresh_symbol(arg1, arg4, v0, arg9, arg10);
        let v1 = RedeemFromPositionEvent{
            collateral_price : sudo::agg_price::price_of(arg5),
            index_price      : sudo::agg_price::price_of(arg6),
            redeem_amount    : arg8,
        };
        (sudo::position::redeem_from_position<T0>(arg2, arg5, arg6, arg7, arg8, arg0.acc_reserving_rate, arg1.acc_funding_rate, arg10), v1)
    }

    fun refresh_symbol(arg0: &mut Symbol, arg1: &sudo::model::FundingFeeModel, arg2: sudo::sdecimal::SDecimal, arg3: sudo::decimal::Decimal, arg4: u64) {
        let v0 = symbol_delta_funding_rate(arg0, arg1, arg2, arg3, arg4);
        arg0.acc_funding_rate = symbol_acc_funding_rate(arg0, v0);
        arg0.unrealised_funding_fee_value = symbol_unrealised_funding_fee_value(arg0, v0);
        arg0.last_update = arg4;
    }

    fun refresh_vault<T0>(arg0: &mut Vault<T0>, arg1: &sudo::model::ReservingFeeModel, arg2: u64) {
        let v0 = vault_delta_reserving_rate<T0>(arg0, arg1, arg2);
        let v1 = sudo::rate::zero();
        if (sudo::rate::gt(&v0, &v1)) {
            arg0.acc_reserving_rate = vault_acc_reserving_rate<T0>(arg0, v0);
            arg0.unrealised_reserving_fee_amount = vault_unrealised_reserving_fee_amount<T0>(arg0, v0);
            arg0.last_update = arg2;
        };
    }

    public(package) fun remove_collateral_from_symbol<T0>(arg0: &mut Symbol) {
        let v0 = 0x1::type_name::get<T0>();
        0x2::vec_set::remove<0x1::type_name::TypeName>(&mut arg0.supported_collaterals, &v0);
    }

    public(package) fun set_symbol_status(arg0: &mut Symbol, arg1: bool, arg2: bool, arg3: bool) {
        arg0.open_enabled = arg1;
        arg0.decrease_enabled = arg2;
        arg0.liquidate_enabled = arg3;
    }

    public(package) fun swap_in<T0>(arg0: &mut Vault<T0>, arg1: &sudo::model::RebaseFeeModel, arg2: &sudo::agg_price::AggPrice, arg3: 0x2::balance::Balance<T0>, arg4: sudo::decimal::Decimal, arg5: sudo::decimal::Decimal, arg6: sudo::decimal::Decimal) : (sudo::decimal::Decimal, sudo::decimal::Decimal) {
        assert!(arg0.enabled, 1);
        let v0 = 0x2::balance::value<T0>(&arg3);
        assert!(v0 > 0, 8);
        0x2::balance::join<T0>(&mut arg0.liquidity, arg3);
        let v1 = sudo::agg_price::coins_to_value(arg2, v0);
        let v2 = sudo::decimal::mul_with_rate(v1, compute_rebase_fee_rate(arg1, true, sudo::decimal::add(arg4, v1), sudo::decimal::add(arg5, v1), arg0.weight, arg6));
        (sudo::decimal::sub(v1, v2), v2)
    }

    public(package) fun swap_out<T0>(arg0: &mut Vault<T0>, arg1: &sudo::model::RebaseFeeModel, arg2: &sudo::agg_price::AggPrice, arg3: u64, arg4: sudo::decimal::Decimal, arg5: sudo::decimal::Decimal, arg6: sudo::decimal::Decimal, arg7: sudo::decimal::Decimal) : (0x2::balance::Balance<T0>, sudo::decimal::Decimal) {
        assert!(arg0.enabled, 1);
        assert!(sudo::decimal::lt(&arg4, &arg5), 2);
        let v0 = sudo::decimal::mul_with_rate(arg4, compute_rebase_fee_rate(arg1, false, sudo::decimal::sub(arg5, arg4), arg6, arg0.weight, arg7));
        let v1 = sudo::decimal::floor_u64(sudo::agg_price::value_to_coins(arg2, sudo::decimal::sub(arg4, v0)));
        assert!(v1 >= arg3, 12);
        assert!(v1 < 0x2::balance::value<T0>(&arg0.liquidity), 3);
        (0x2::balance::split<T0>(&mut arg0.liquidity, v1), v0)
    }

    public fun symbol_acc_funding_rate(arg0: &Symbol, arg1: sudo::srate::SRate) : sudo::srate::SRate {
        sudo::srate::add(arg0.acc_funding_rate, arg1)
    }

    public fun symbol_decrease_enabled(arg0: &Symbol) : bool {
        arg0.decrease_enabled
    }

    public fun symbol_delta_funding_rate(arg0: &Symbol, arg1: &sudo::model::FundingFeeModel, arg2: sudo::sdecimal::SDecimal, arg3: sudo::decimal::Decimal, arg4: u64) : sudo::srate::SRate {
        if (arg0.last_update > 0) {
            let v0 = arg4 - arg0.last_update;
            if (v0 > 0) {
                return sudo::model::compute_funding_fee_rate(arg1, symbol_pnl_per_lp(arg0, arg2, arg3), v0)
            };
        };
        sudo::srate::zero()
    }

    public fun symbol_delta_size(arg0: &Symbol, arg1: &sudo::agg_price::AggPrice, arg2: bool) : sudo::sdecimal::SDecimal {
        let v0 = sudo::agg_price::coins_to_value(arg1, arg0.opening_amount);
        let (mut v1, mut v2) = if (sudo::decimal::gt(&v0, &arg0.opening_size)) {
            (!arg2, sudo::decimal::sub(v0, arg0.opening_size))
        } else {
            (arg2, sudo::decimal::sub(arg0.opening_size, v0))
        };
        sudo::sdecimal::from_decimal(v1, v2)
    }

    public fun symbol_funding_fee_model(arg0: &Symbol) : &0x2::object::ID {
        &arg0.funding_fee_model
    }

    public fun symbol_liquidate_enabled(arg0: &Symbol) : bool {
        arg0.liquidate_enabled
    }

    public fun symbol_open_enabled(arg0: &Symbol) : bool {
        arg0.open_enabled
    }

    public fun symbol_opening_amount(arg0: &Symbol) : u64 {
        arg0.opening_amount
    }

    public fun symbol_opening_size(arg0: &Symbol) : sudo::decimal::Decimal {
        arg0.opening_size
    }

    public fun symbol_pnl_per_lp(arg0: &Symbol, arg1: sudo::sdecimal::SDecimal, arg2: sudo::decimal::Decimal) : sudo::sdecimal::SDecimal {
        sudo::sdecimal::div_by_decimal(sudo::sdecimal::add(sudo::sdecimal::add(arg0.realised_pnl, arg0.unrealised_funding_fee_value), arg1), arg2)
    }

    public fun symbol_price_config(arg0: &Symbol) : &sudo::agg_price::AggPriceConfig {
        &arg0.price_config
    }

    public fun symbol_supported_collaterals(arg0: &Symbol) : &0x2::vec_set::VecSet<0x1::type_name::TypeName> {
        &arg0.supported_collaterals
    }

    public fun symbol_unrealised_funding_fee_value(arg0: &Symbol, arg1: sudo::srate::SRate) : sudo::sdecimal::SDecimal {
        sudo::sdecimal::add(arg0.unrealised_funding_fee_value, sudo::sdecimal::from_decimal(sudo::srate::is_positive(&arg1), sudo::decimal::mul_with_rate(arg0.opening_size, sudo::srate::value(&arg1))))
    }

    fun truncate_decimal(arg0: sudo::decimal::Decimal) : u64 {
        ((sudo::decimal::to_raw(arg0) / 1000000000000) as u64)
    }

    public(package) fun unwrap_decrease_position_result<T0>(arg0: DecreasePositionResult<T0>) : (0x2::balance::Balance<T0>, 0x2::balance::Balance<T0>, DecreasePositionSuccessEvent) {
        let DecreasePositionResult<T0> {
            to_trader : v0,
            rebate    : v1,
            event     : v2,
        } = arg0;
        (v0, v1, v2)
    }

    public(package) fun unwrap_open_position_result<T0>(arg0: OpenPositionResult<T0>) : (sudo::position::Position<T0>, 0x2::balance::Balance<T0>, OpenPositionSuccessEvent) {
        let OpenPositionResult<T0> {
            position : v0,
            rebate   : v1,
            event    : v2,
        } = arg0;
        (v0, v1, v2)
    }

    public(package) fun valuate_symbol(arg0: &mut Symbol, arg1: &sudo::model::FundingFeeModel, arg2: &sudo::agg_price::AggPrice, arg3: bool, arg4: sudo::decimal::Decimal, arg5: u64) : sudo::sdecimal::SDecimal {
        assert!(0x2::object::id<sudo::model::FundingFeeModel>(arg1) == arg0.funding_fee_model, 14);
        let v0 = symbol_delta_size(arg0, arg2, arg3);
        refresh_symbol(arg0, arg1, v0, arg4, arg5);
        sudo::sdecimal::add(v0, arg0.unrealised_funding_fee_value)
    }

    public(package) fun valuate_vault<T0>(arg0: &mut Vault<T0>, arg1: &sudo::model::ReservingFeeModel, arg2: &sudo::agg_price::AggPrice, arg3: u64) : sudo::decimal::Decimal {
        assert!(arg0.enabled, 1);
        assert!(0x2::object::id<sudo::model::ReservingFeeModel>(arg1) == arg0.reserving_fee_model, 13);
        refresh_vault<T0>(arg0, arg1, arg3);
        sudo::agg_price::coins_to_value(arg2, sudo::decimal::floor_u64(vault_supply_amount<T0>(arg0)))
    }

    public fun vault_acc_reserving_rate<T0>(arg0: &Vault<T0>, arg1: sudo::rate::Rate) : sudo::rate::Rate {
        sudo::rate::add(arg0.acc_reserving_rate, arg1)
    }

    public fun vault_delta_reserving_rate<T0>(arg0: &Vault<T0>, arg1: &sudo::model::ReservingFeeModel, arg2: u64) : sudo::rate::Rate {
        if (arg0.last_update > 0 && arg0.reserved_amount > 0) {
            let v0 = arg2 - arg0.last_update;
            if (v0 > 0) {
                return sudo::model::compute_reserving_fee_rate(arg1, vault_utilization<T0>(arg0), v0)
            };
        };
        sudo::rate::zero()
    }

    public fun vault_enabled<T0>(arg0: &Vault<T0>) : bool {
        arg0.enabled
    }

    public fun vault_liquidity_amount<T0>(arg0: &Vault<T0>) : u64 {
        0x2::balance::value<T0>(&arg0.liquidity)
    }

    public fun vault_price_config<T0>(arg0: &Vault<T0>) : &sudo::agg_price::AggPriceConfig {
        &arg0.price_config
    }

    public fun vault_reserved_amount<T0>(arg0: &Vault<T0>) : u64 {
        arg0.reserved_amount
    }

    public fun vault_reserving_fee_model<T0>(arg0: &Vault<T0>) : &0x2::object::ID {
        &arg0.reserving_fee_model
    }

    public fun vault_supply_amount<T0>(arg0: &Vault<T0>) : sudo::decimal::Decimal {
        sudo::decimal::add(sudo::decimal::from_u64(0x2::balance::value<T0>(&arg0.liquidity) + arg0.reserved_amount), arg0.unrealised_reserving_fee_amount)
    }

    public fun vault_unrealised_reserving_fee_amount<T0>(arg0: &Vault<T0>, arg1: sudo::rate::Rate) : sudo::decimal::Decimal {
        sudo::decimal::add(arg0.unrealised_reserving_fee_amount, sudo::decimal::mul_with_rate(sudo::decimal::from_u64(arg0.reserved_amount), arg1))
    }

    public fun vault_utilization<T0>(arg0: &Vault<T0>) : sudo::rate::Rate {
        let v0 = vault_supply_amount<T0>(arg0);
        if (sudo::decimal::is_zero(&v0)) {
            sudo::rate::zero()
        } else {
            sudo::decimal::to_rate(sudo::decimal::div(sudo::decimal::from_u64(arg0.reserved_amount), v0))
        }
    }

    public fun vault_weight<T0>(arg0: &Vault<T0>) : sudo::decimal::Decimal {
        arg0.weight
    }

    public(package) fun withdraw<T0>(arg0: &mut Vault<T0>, arg1: &sudo::model::RebaseFeeModel, arg2: &sudo::agg_price::AggPrice, arg3: u64, arg4: u64, arg5: u64, arg6: sudo::decimal::Decimal, arg7: sudo::decimal::Decimal, arg8: sudo::decimal::Decimal, arg9: sudo::decimal::Decimal) : (0x2::balance::Balance<T0>, sudo::decimal::Decimal) {
        assert!(arg0.enabled, 1);
        assert!(arg3 > 0, 10);
        let v0 = sudo::decimal::mul_with_rate(arg6, sudo::decimal::to_rate(sudo::decimal::div(sudo::decimal::from_u64(arg3), sudo::decimal::from_u64(arg5))));
        assert!(sudo::decimal::le(&v0, &arg7), 2);
        let v1 = sudo::decimal::mul_with_rate(v0, compute_rebase_fee_rate(arg1, false, sudo::decimal::sub(arg7, v0), sudo::decimal::sub(arg8, v0), arg0.weight, arg9));
        let v2 = sudo::decimal::floor_u64(sudo::agg_price::value_to_coins(arg2, sudo::decimal::sub(v0, v1)));
        assert!(v2 <= 0x2::balance::value<T0>(&arg0.liquidity), 3);
        let v3 = 0x2::balance::split<T0>(&mut arg0.liquidity, v2);
        assert!(0x2::balance::value<T0>(&v3) >= arg4, 12);
        (v3, v1)
    }

    // decompiled from Move bytecode v6
}

