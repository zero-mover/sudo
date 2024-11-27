module sudo::slp {
    public struct SLP has drop {
        dummy_field: bool,
    }

    fun init(arg0: SLP, arg1: &mut 0x2::tx_context::TxContext) {
        sudo::admin::create_admin_cap(arg1);
        let (v0, v1) = 0x2::coin::create_currency<SLP>(arg0, 6, b"SLP", b"Sudo LP Token", b"LP Token for Sudo Market", 0x1::option::some<0x2::url::Url>(0x2::url::new_unsafe_from_bytes(b"https://arweave.net/_SEJoeyOw0uVJbu-kcJZ1BFP1E5j4OWOdQnv4s51rU0")), arg1);
        0x2::transfer::public_freeze_object<0x2::coin::CoinMetadata<SLP>>(v1);
        sudo::market::create_market<SLP>(0x2::coin::treasury_into_supply<SLP>(v0), sudo::rate::from_percent(5), arg1);
    }

    // decompiled from Move bytecode v6
}

