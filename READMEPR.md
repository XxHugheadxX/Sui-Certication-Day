Sui Soulbound Certification Protocol 🎓⛓️

📄 Descripción del Proyecto

Este protocolo implementa un sistema de Certificados Digitales Inmutables en la red de Sui, utilizando la arquitectura de Tokens Soulbound (SBT).

El objetivo es resolver el problema de la identidad académica y la asistencia a eventos en la Web3. A diferencia de los NFTs tradicionales que pueden ser comercializados, estos certificados están vinculados criptográficamente a la billetera del receptor y no poseen mecanismos de transferencia pública, garantizando que el mérito permanezca con el individuo que lo obtuvo.

🌟 Características Principales

🛡️ Arquitectura Soulbound: Diseño estricto que impide la transferencia del token una vez emitido.

🖼️ Estándar Sui Display: Implementación nativa para la renderización automática de metadatos e imágenes en cualquier wallet o explorador del ecosistema Sui.

🌐 Integración IPFS: Almacenamiento descentralizado de los activos visuales (imágenes de certificados) asegurando la persistencia de los datos.

🔐 Seguridad AdminCap: Sistema de permisos basado en capacidades (Capabilities) donde solo el administrador autorizado puede acuñar nuevos certificados.

⚙️ Arquitectura del Smart Contract

El módulo sui_poap está escrito en Sui Move y consta de componentes clave diseñados para la seguridad y la experiencia de usuario.

1. Estructuras de Datos (Structs)

SUI_POAP (One Time Witness):

Un patrón de diseño obligatorio en Sui. Asegura que la configuración del Display solo pueda ser ejecutada una vez por el módulo legítimo.

AdminCap (Capability):

Es la "Llave Maestra". Un objeto único que se transfiere al creador del contrato al momento del despliegue. Sin este objeto, es imposible llamar a la función de minting.

Poap (El Certificado):

El objeto NFT en sí mismo. Contiene los campos: nombre_evento, fecha, ubicacion, hash_imagen (CID de IPFS) y descripcion.

Posee las habilidades key (es un objeto único en la red) y store (puede ser almacenado).

2. Funciones del Módulo

fun init(otw: SUI_POAP, ctx: &mut TxContext)

Se ejecuta automáticamente al publicar el contrato.

Rol: Configura el estándar visual (Sui Display).

Lógica: Define una plantilla dinámica donde image_url se construye concatenando https://ipfs.io/ipfs/ + {hash_imagen}. Esto permite que el frontend solo maneje hashes ligeros mientras la wallet muestra la imagen completa.

public fun mint_poap(...)

La función core del protocolo.

Argumentos: Requiere la referencia a AdminCap, datos del evento y la dirección del recipient.

Mecanismo Soulbound: Crea el objeto Poap y utiliza transfer::transfer para enviarlo al destinatario. Al no exponer una función pública complementaria para retirar o enviar este objeto, el token queda efectivamente "atado" a la cuenta del usuario.

🚀 Guía de Uso (CLI)

Pre-requisitos

Sui Binaries instalados (v1.61.1 o superior).

Una wallet activa con fondos (SUI) para gas.

1. Publicar el Contrato

sui client publish --gas-budget 100000000 --skip-fetch-latest-git-deps


Guarda el Package ID y el AdminCap ID de la salida de la consola.

2. Emitir un Certificado (Mint)

Ejecuta el siguiente comando reemplazando los valores entre < >:

sui client call \
  --package <PACKAGE_ID> \
  --module sui_poap \
  --function mint_poap \
  --args \
    <ADMIN_CAP_ID> \
    "Nombre del Evento" \
    <TIMESTAMP_FECHA> \
    "Ubicación del Evento" \
    "HASH_IPFS_DE_LA_IMAGEN" \
    "Descripción del logro" \
    <WALLET_DEL_ESTUDIANTE> \
  --gas-budget 100000000


🔮 Escalabilidad e Integración Frontend

Este contrato está diseñado para ser la capa base de una plataforma educativa masiva. Su potencial de escalabilidad incluye:

1. Minting Masivo (Batch Minting)

Actualmente, el contrato emite uno por uno. Para escalar a miles de usuarios, el Frontend puede utilizar Programmable Transaction Blocks (PTBs) de Sui.

Cómo funciona: Un script de TypeScript puede agrupar hasta 1024 llamadas a la función mint_poap en una sola transacción, reduciendo costos de gas y tiempos de espera drásticamente.

2. Automatización con API Web2

Se puede integrar un backend (Node.js/Python) que:

Reciba los datos del estudiante.

Genere la imagen del diploma dinámicamente.

Suba la imagen a Pinata (IPFS) vía API.

Obtenga el Hash y firme la transacción en Sui automáticamente.

3. Indexación y Discovery

Gracias a la implementación de Sui Display, no se requiere un indexador personalizado complejo. Cualquier dApp puede leer los objetos del usuario, filtrar por el tipo Poap y mostrar instantáneamente su galería de logros usando la API estándar de Sui GraphQL.

🛠️ Tech Stack

Blockchain: Sui Network (Mainnet/Testnet)

Lenguaje: Move (Sui Flavor)

Almacenamiento: IPFS (InterPlanetary File System)

Estándar: Sui Object Display Standard

Hecho con ❤️ y Move.