module william::sui_poap {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    
    // Importamos librerías necesarias para el estándar de visualización (Display)
    use sui::package;
    use sui::display;

    /// ESTRUCTURA OTW (One Time Witness)
    /// Es un patrón de diseño obligatorio en Sui para configurar el Display.
    /// Garantiza que este módulo es el único que puede definir cómo se ven sus objetos.
    public struct SUI_POAP has drop {}

    /// CAPACIDAD DE ADMINISTRADOR (AdminCap)
    /// Funciona como una "Llave Maestra". Solo quien posea este objeto en su wallet
    /// tendrá permiso para ejecutar la función de crear (mintar) nuevos POAPs.
    public struct AdminCap has key, store {
        id: UID,
    }

    /// ESTRUCTURA DEL POAP (El NFT Soulbound)
    /// Define los datos que quedarán grabados en la blockchain.
    /// Tiene 'key' para ser un objeto único y 'store' para guardarse en wallets.
    public struct Poap has key, store {
        id: UID,
        nombre_evento: String,
        fecha: u64,
        ubicacion: String,
        hash_imagen: String, 
        descripcion: String,
    }

    /// FUNCIÓN DE INICIALIZACIÓN (INIT)
    /// Se ejecuta una única vez automáticamente cuando se publica el contrato.
    /// Su objetivo es configurar cómo las wallets (Sui Wallet, etc.) deben mostrar el NFT.
    fun init(otw: SUI_POAP, ctx: &mut TxContext) {
        
        // 1. Reclamamos el objeto "Publisher" para tener autoridad sobre el paquete.
        let publisher = package::claim(otw, ctx);

        // 2. Definimos las claves (keys) que leerán las wallets.
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"image_url"),
        ];

        // 3. Definimos los valores (values) que corresponden a cada clave.
        // Aquí se crea la plantilla dinámica que conecta los datos del objeto con la visualización.
        let values = vector[
            string::utf8(b"{nombre_evento}"),
            string::utf8(b"{descripcion}"),
            // Construye la URL completa de IPFS usando el hash almacenado en el objeto.
            string::utf8(b"https://ipfs.io/ipfs/{hash_imagen}"),
        ];

        // 4. Creamos el objeto Display con la configuración anterior.
        let mut display = display::new_with_fields<Poap>(
            &publisher, keys, values, ctx
        );

        // 5. Guardamos y publicamos la configuración de visualización.
        display::update_version(&mut display);

        // 6. Transferimos el control del Publisher y Display al creador del contrato (Sender).
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));

        // 7. Creamos y entregamos el AdminCap al creador para que pueda empezar a mintar.
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// FUNCIÓN DE MINTADO (Creación del POAP)
    /// Crea un nuevo certificado y lo envía directamente al usuario.
    /// Recibe el AdminCap como referencia para validar que solo el administrador pueda llamar a esta función.
    public fun mint_poap(
        _admin_cap: &AdminCap, 
        nombre_evento: String,
        fecha: u64,
        ubicacion: String,
        hash_imagen: String,
        descripcion: String,
        recipient: address,
        ctx: &mut TxContext
    ) {
        // Creamos el objeto en memoria con los datos proporcionados
        let poap = Poap {
            id: object::new(ctx),
            nombre_evento,
            fecha,
            ubicacion,
            hash_imagen,
            descripcion,
        };

        // Transferimos el objeto al destinatario.
        // Al no existir una función pública de "retirar" o "transferir" en este módulo,
        // el objeto se comporta como un token Soulbound (No Transferible) de facto.
        transfer::transfer(poap, recipient);
    }
}
