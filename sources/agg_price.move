module sudo::agg_price {
    public struct AggPrice has drop, store {
        price: sudo::decimal::Decimal,
        precision: u64,
    }

    public struct AggPriceConfig has store {
        max_interval: u64,
        max_confidence: u64,
        precision: u64,
        feeder: 0x2::object::ID,
    }

    public fun coins_to_value(arg0: &AggPrice, arg1: u64) : sudo::decimal::Decimal {
        sudo::decimal::div_by_u64(sudo::decimal::mul_with_u64(arg0.price, arg1), arg0.precision)
    }

    public fun from_price(arg0: &AggPriceConfig, arg1: sudo::decimal::Decimal) : AggPrice {
        AggPrice{
            price     : arg1,
            precision : arg0.precision,
        }
    }

    fun get_abs_diff(arg0: u64, arg1: u64) : u64 {
        if (arg0 > arg1) {
            return arg0 - arg1
        };
        arg1 - arg0
    }

    public(package) fun new_agg_price_config<T0>(arg0: u64, arg1: u64, arg2: &0x2::coin::CoinMetadata<T0>, arg3: &0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price_info::PriceInfoObject) : AggPriceConfig {
        AggPriceConfig{
            max_interval   : arg0,
            max_confidence : arg1,
            precision      : 0x2::math::pow(10, 0x2::coin::get_decimals<T0>(arg2)),
            feeder         : 0x2::object::id<0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price_info::PriceInfoObject>(arg3),
        }
    }

    public(package) fun new_agg_price_config_v1_1<T0>(arg0: u64, arg1: u64, arg2: &0x2::coin::CoinMetadata<T0>, arg3: &0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price_info::PriceInfoObject) : AggPriceConfig {
        AggPriceConfig{
            max_interval   : arg0,
            max_confidence : arg1,
            precision      : 0x2::math::pow(10, 0x2::coin::get_decimals<T0>(arg2)),
            feeder         : 0x2::object::id<0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price_info::PriceInfoObject>(arg3),
        }
    }

    public fun parse_pyth_feeder(arg0: &AggPriceConfig, arg1: &0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price_info::PriceInfoObject, arg2: u64) : AggPrice {
        assert!(0x2::object::id<0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price_info::PriceInfoObject>(arg1) == arg0.feeder, 1);
        let v0 = 0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::pyth::get_price_unsafe(arg1);
        assert!(get_abs_diff(0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price::get_timestamp(&v0), arg2) <= arg0.max_interval, 2);
        assert!(0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price::get_conf(&v0) <= arg0.max_confidence, 3);
        let v1 = 0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price::get_price(&v0);
        let v2 = 0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::i64::get_magnitude_if_positive(&v1);
        assert!(v2 > 0, 4);
        let v3 = 0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::price::get_expo(&v0);
        let mut v4 = if (0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::i64::get_is_negative(&v3)) {
            sudo::decimal::div_by_u64(sudo::decimal::from_u64(v2), 0x2::math::pow(10, (0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::i64::get_magnitude_if_negative(&v3) as u8)))
        } else {
            sudo::decimal::mul_with_u64(sudo::decimal::from_u64(v2), 0x2::math::pow(10, (0xb53b0f4174108627fbee72e2498b58d6a2714cded53fac537034c220d26302::i64::get_magnitude_if_positive(&v3) as u8)))
        };
        AggPrice{
            price     : v4,
            precision : arg0.precision,
        }
    }

    public fun parse_pyth_feeder_v1_1(arg0: &AggPriceConfig, arg1: &0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price_info::PriceInfoObject, arg2: u64) : AggPrice {
        assert!(0x2::object::id<0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price_info::PriceInfoObject>(arg1) == arg0.feeder, 1);
        let v0 = 0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::pyth::get_price_unsafe(arg1);
        assert!(get_abs_diff(0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price::get_timestamp(&v0), arg2) <= arg0.max_interval, 2);
        assert!(0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price::get_conf(&v0) <= arg0.max_confidence, 3);
        let v1 = 0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price::get_price(&v0);
        let v2 = 0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::i64::get_magnitude_if_positive(&v1);
        assert!(v2 > 0, 4);
        let v3 = 0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price::get_expo(&v0);
        let mut v4 = if (0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::i64::get_is_negative(&v3)) {
            sudo::decimal::div_by_u64(sudo::decimal::from_u64(v2), 0x2::math::pow(10, (0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::i64::get_magnitude_if_negative(&v3) as u8)))
        } else {
            sudo::decimal::mul_with_u64(sudo::decimal::from_u64(v2), 0x2::math::pow(10, (0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::i64::get_magnitude_if_positive(&v3) as u8)))
        };
        AggPrice{
            price     : v4,
            precision : arg0.precision,
        }
    }

    public fun precision_of(arg0: &AggPrice) : u64 {
        arg0.precision
    }

    public fun price_of(arg0: &AggPrice) : sudo::decimal::Decimal {
        arg0.price
    }

    public(package) fun update_agg_price_config_feeder(arg0: &mut AggPriceConfig, arg1: &0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price_info::PriceInfoObject) {
        arg0.feeder = 0x2::object::id<0x8d97f1cd6ac663735be08d1d2b6d02a159e711586461306ce60a2b7a6a565a9e::price_info::PriceInfoObject>(arg1);
    }

    public fun value_to_coins(arg0: &AggPrice, arg1: sudo::decimal::Decimal) : sudo::decimal::Decimal {
        sudo::decimal::div(sudo::decimal::mul_with_u64(arg1, arg0.precision), arg0.price)
    }

    // decompiled from Move bytecode v6
}

