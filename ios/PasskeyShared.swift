//
// https://github.com/peterferguson/react-native-passkeys
//

import AuthenticationServices

typealias Base64URLString = String

enum Either<Create, Get> {
    case create(Create), get(Get)
}

extension Array {
    var data: Data { withUnsafeBytes { .init($0) } }
}

extension Data {
    func toUIntArray() -> [UInt] {
        var UIntArray = Array<UInt>(repeating: 0, count: self.count/MemoryLayout<UInt>.stride);
        _ = UIntArray.withUnsafeMutableBytes { self.copyBytes(to: $0) }
        return UIntArray;
    }
    var uIntArray: [UInt] { toUIntArray() }
}

/**
    Specification reference: https://w3c.github.io/webauthn/#enum-transport
*/
@available(iOS 15.0, *)
internal enum AuthenticatorTransport: String, Codable {
    case ble
    case hybrid
    case nfc
    case usb
  
    func appleise() -> ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport? {
        switch self {
        case .ble:
            return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.bluetooth
        case .nfc:
            return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.nfc
        case .usb:
            return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.usb
        default:
            return nil
        }
    }
}

/**
    Specification reference: https://w3c.github.io/webauthn/#enum-attachment
*/
internal enum AuthenticatorAttachment: String, Codable {
    case platform
  
    // - cross-platform marks that the user wants to select a security key
    case crossPlatform = "cross-platform"
}

/**
    Specification reference: https://w3c.github.io/webauthn/#enum-attestation-convey
*/
@available(iOS 15.0, *)
internal enum AttestationConveyancePreference: String, Decodable {
    case direct
    case enterprise
    case indirect
    case none

    func appleise() -> ASAuthorizationPublicKeyCredentialAttestationKind {
        switch self {
        case .direct:
            return ASAuthorizationPublicKeyCredentialAttestationKind.direct
        case .indirect:
            return ASAuthorizationPublicKeyCredentialAttestationKind.indirect
        case .enterprise:
            return ASAuthorizationPublicKeyCredentialAttestationKind.enterprise
        default:
            return ASAuthorizationPublicKeyCredentialAttestationKind.direct
        }
    }
}

/**
    Specification reference: https://w3c.github.io/webauthn/#enum-credentialType
*/
internal enum PublicKeyCredentialType: String, Codable {
    case publicKey = "public-key"
}

/**
    Specification reference: https://w3c.github.io/webauthn/#enum-userVerificationRequirement
*/
@available(iOS 15.0, *)
internal enum UserVerificationRequirement: String, Codable {
    case discouraged
    case preferred
    case required

    func appleise () -> ASAuthorizationPublicKeyCredentialUserVerificationPreference {
        switch self {
        case .discouraged:
            return ASAuthorizationPublicKeyCredentialUserVerificationPreference.discouraged
        case .preferred:
            return ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred
        case .required:
            return ASAuthorizationPublicKeyCredentialUserVerificationPreference.required
        default:
            return ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred
        }
    }
}

/**
    Specification reference: https://w3c.github.io/webauthn/#enum-residentKeyRequirement
*/
@available(iOS 15.0, *)
internal enum ResidentKeyRequirement: String, Decodable {
    case discouraged
    case preferred
    case required

    func appleise() -> ASAuthorizationPublicKeyCredentialResidentKeyPreference {
        switch self {
        case .discouraged:
            return ASAuthorizationPublicKeyCredentialResidentKeyPreference.discouraged
        case .preferred:
            return ASAuthorizationPublicKeyCredentialResidentKeyPreference.preferred
        case .required:
            return ASAuthorizationPublicKeyCredentialResidentKeyPreference.required
        default:
            return ASAuthorizationPublicKeyCredentialResidentKeyPreference.preferred
        }
    }
}

/**
    Specification reference: https://w3c.github.io/webauthn/#enumdef-largeblobsupport
*/
internal enum LargeBlobSupport: String {
    case preferred
    case required
  
  @available(iOS 17.0, *)
  func appleise() -> ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput? {
      switch self {
      case .preferred:
        return ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput.supportPreferred
      case .required:
        return ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput.supportRequired
      default:
          return nil
      }
  }
}

// - Structs

/**
    Specification reference: https://w3c.github.io/webauthn/#dictionary-authenticatorSelection
*/
@available(iOS 15.0, *)
internal struct AuthenticatorSelectionCriteria: Decodable {
  var authenticatorAttachment: AuthenticatorAttachment?
  
  var residentKey: ResidentKeyRequirement?
  
  var requireResidentKey: Bool? = false;
  
  var userVerification: UserVerificationRequirement? = UserVerificationRequirement.preferred;
  
  enum CodingKeys: String, CodingKey {
    case authenticatorAttachment
    case residentKey
    case requireResidentKey
    case userVerification
  }
  
  // We have to manually decode this
  init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self);
    
    let authenticatorAttachmentValue = try values.decodeIfPresent(String.self, forKey: .authenticatorAttachment);
    if let authenticatorAttachmentString = authenticatorAttachmentValue {
      authenticatorAttachment = AuthenticatorAttachment(rawValue: authenticatorAttachmentString);
    }
    
    let residentKeyValue = try values.decodeIfPresent(String.self, forKey: .residentKey);
    if let residentKeyString = residentKeyValue {
      residentKey = ResidentKeyRequirement(rawValue: residentKeyString);
    }
    
    requireResidentKey = try values .decodeIfPresent(Bool.self, forKey: .requireResidentKey);
    
    let userVerificationValue = try values.decodeIfPresent(String.self, forKey: .userVerification);
    if let userVerificationString = userVerificationValue {
      userVerification = UserVerificationRequirement(rawValue: userVerificationString);
    }
  }
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictionary-pkcredentialentity
*/
internal struct PublicKeyCredentialEntity: Decodable {
    var name: String
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictionary-credential-params
*/
@available(iOS 15.0, *)
internal struct PublicKeyCredentialParameters: Decodable {
  var alg: ASCOSEAlgorithmIdentifier = .ES256
  
  var type: PublicKeyCredentialType = .publicKey
  
  func appleise() -> ASAuthorizationPublicKeyCredentialParameters {
    return ASAuthorizationPublicKeyCredentialParameters.init(algorithm: ASCOSEAlgorithmIdentifier(self.alg.rawValue))
  }
  
  enum CodingKeys: String, CodingKey {
    case alg
    case type
  }
  
  // We have to manually decode this
  init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self);
    
    let algValue = try values.decodeIfPresent(Int.self, forKey: .alg);
    if let algInt = algValue {
      alg = ASCOSEAlgorithmIdentifier(algInt);
    }

    let typeValue = try values.decodeIfPresent(String.self, forKey: .type);
    if let typeString = typeValue {
      type = PublicKeyCredentialType(rawValue: typeString) ?? .publicKey;
    }
  }
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictionary-rp-credential-params
*/
internal struct PublicKeyCredentialRpEntity: Decodable {
  
  var name: String
  
  var id: String?
}

/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-publickeycredentialuserentity
*/
internal struct PublicKeyCredentialUserEntity: Decodable {

  var name: String

  var displayName: String

  var id: String
}


/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-publickeycredentialdescriptor
*/
@available(iOS 15.0, *)
internal struct PublicKeyCredentialDescriptor: Decodable {

  var id: Base64URLString

  var transports: [AuthenticatorTransport]?

  var type: PublicKeyCredentialType = .publicKey

  func getPlatformDescriptor() -> ASAuthorizationPlatformPublicKeyCredentialDescriptor {
    return ASAuthorizationPlatformPublicKeyCredentialDescriptor.init(credentialID: Data(base64URLEncoded: self.id)!)
  }
    
  func getCrossPlatformDescriptor() -> ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor {
    var transports = ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.allSupported
    
    if self.transports?.isEmpty == false {
      transports = self.transports!.compactMap { $0.appleise() }
    }
    
    return ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.init(credentialID: Data(base64URLEncoded: self.id)!,
                                                                        transports: transports)
  }
  
  enum CodingKeys: String, CodingKey {
    case id
    case transports
    case type
  }
  
  // We have to manually decode this
  init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self);
    
    id = try values.decodeIfPresent(String.self, forKey: .id)!;
    
    transports = try values.decodeIfPresent([AuthenticatorTransport].self, forKey: .transports);

    let typeValue = try values.decodeIfPresent(String.self, forKey: .type);
    if let typeString = typeValue {
      type = PublicKeyCredentialType(rawValue: typeString) ?? .publicKey
    }
  }
}


/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticationextensionslargeblobinputs
*/
internal struct AuthenticationExtensionsLargeBlobInputs: Decodable {
  // - Only valid during registration.
  var support: LargeBlobSupport?
    
  // - A boolean that indicates that the Relying Party would like to fetch the previously-written blob associated with the asserted credential. Only valid during authentication.
  var read: Bool?
    
  // - An opaque byte string that the Relying Party wishes to store with the existing credential. Only valid during authentication.
  // - We impose that the data is passed as base64-url encoding to make better align the passing of data from RN to native code
  var write: Data?
  
  enum CodingKeys: String, CodingKey {
    case support
    case read
    case write
  }
  
  // We have to manually decode this
  init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self);
    
    let supportValue = try values.decodeIfPresent(String.self, forKey: .support);
    if let supportString = supportValue {
      support = LargeBlobSupport(rawValue: supportString);
    }
    
    read = try values.decodeIfPresent(Bool.self, forKey: .read);
    
    // RN converts UInt8Array to Dictionary, need to decode it
    let writeDict = try values.decodeIfPresent([String : Int].self, forKey: .write);
    // sort dict, convert to array and then data
    write = writeDict?.sorted(by: { $0.key < $1.key }).map({ $0.value }).data;
  }
}

internal struct AuthenticationExtensionsPRFInputs: Decodable {
        struct Eval: Decodable {
            var first: Data

            enum CodingKeys: String, CodingKey {
                case first
            }

            init(from decoder: any Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                
                // RN converts UInt8Array to Dictionary; decode it
                let firstDict = try values.decodeIfPresent([String: Int].self, forKey: .first)
                if let dict = firstDict {
                    let sortedValues = dict.sorted(by: { $0.key < $1.key }).map { UInt8($0.value) }
                    first = Data(sortedValues)
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .first, in: values, debugDescription: "Failed to decode 'first'")
                }
            }
        }
        
        var eval: Eval

        enum CodingKeys: String, CodingKey {
            case eval
        }

        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            eval = try values.decode(Eval.self, forKey: .eval)
        }
    }


/**
    Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticationextensionsclientinputs
*/
internal struct AuthenticationExtensionsClientInputs: Decodable {
  var largeBlob: AuthenticationExtensionsLargeBlobInputs?
  var prf: AuthenticationExtensionsPRFInputs?
}

// ! There is only one webauthn extension currently supported on iOS as of iOS 17.0:
// - largeBlob extension: https://w3c.github.io/webauthn/#sctn-large-blob-extension

internal struct AuthenticationExtensionsClientOutputs {
  
  /**
  Specification reference: https://w3c.github.io/webauthn/#dictdef-authenticationextensionslargebloboutputs
   */
  internal struct AuthenticationExtensionsLargeBlobOutputs {
    // - true if, and only if, the created credential supports storing large blobs. Only present in registration outputs.
    let supported: Bool?
    
    // - The opaque byte string that was associated with the credential identified by rawId. Only valid if read was true.
    let blob: Data?
    
    // - A boolean that indicates that the contents of write were successfully stored on the authenticator, associated with the specified credential.
    let  written: Bool?;
  }
  
  internal struct AuthenticationExtensionsPrfOutputs {
    internal struct AuthenticationExtensionsPRFValues {
      let first: Data
      let second: Data?
    }
    let eval: AuthenticationExtensionsPRFValues?
  }
  
  
  let largeBlob: AuthenticationExtensionsLargeBlobOutputs?
  let prf: AuthenticationExtensionsPrfOutputs?
}
