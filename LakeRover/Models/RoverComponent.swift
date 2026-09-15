import Foundation

/// A part of the rover the Reality Composer scene can notify the app about.
/// The raw value *is* the notification identifier — see `docs/reality-composer-contract.md`.
enum RoverComponent: String, CaseIterable, Identifiable, Sendable {
    case antenaGPS
    case panelSolar
    case kamera360
    case pensampel
    case pendorong

    var id: String { rawValue }

    /// Object name in the Reality Composer scene.
    var entityName: String {
        switch self {
        case .antenaGPS: "AntenaGPS"
        case .panelSolar: "PanelSolar"
        case .kamera360: "Kamera360"
        case .pensampel: "Pensampel"
        case .pendorong: "Pendorong"
        }
    }

    var title: String {
        switch self {
        case .antenaGPS: "Antena GPS · 4G"
        case .panelSolar: "Panel solar 40 W"
        case .kamera360: "Kamera 360°"
        case .pensampel: "Sistem pensampelan"
        case .pendorong: "Pendorong"
        }
    }

    var role: String {
        switch self {
        case .antenaGPS: "Kedudukan & pautan"
        case .panelSolar: "Tenaga"
        case .kamera360: "Pemantauan"
        case .pensampel: "Ambil sampel"
        case .pendorong: "Gerakan"
        }
    }

    var explanation: String {
        switch self {
        case .antenaGPS:
            "Menentukan kedudukan rover dengan ketepatan kira-kira 2 m dan menghantar telemetri melalui 4G ke iPad."
        case .panelSolar:
            "Mengecas bateri sepanjang misi dan menjana sehingga 40 W pada hari cerah, jadi rover boleh bekerja lebih lama."
        case .kamera360:
            "Memberi pandangan penuh permukaan air untuk mengelak halangan dan merekod keadaan tasik."
        case .pensampel:
            "Pam menarik air melalui kartrij penapis ke dalam botol 5 L — satu kartrij bertag RFID untuk setiap stesen."
        case .pendorong:
            "Dua motor pendorong menggerakkan rover pada 1.2 m/s dan menahan kedudukan semasa pensampelan."
        }
    }

    var symbol: String {
        switch self {
        case .antenaGPS: "antenna.radiowaves.left.and.right"
        case .panelSolar: "sun.max.fill"
        case .kamera360: "camera.fill"
        case .pensampel: "drop.fill"
        case .pendorong: "fan.fill"
        }
    }

    var group: RoverGroup {
        switch self {
        case .antenaGPS, .panelSolar, .kamera360: .showElektronik
        case .pensampel: .showPensampel
        case .pendorong: .showPropulsi
        }
    }
}

/// Group chips on the Rover Model screen. Raw value is the app → model trigger identifier.
enum RoverGroup: String, CaseIterable, Sendable {
    case showAll
    case showPensampel
    case showElektronik
    case showPropulsi

    var label: String {
        switch self {
        case .showAll: "Keseluruhan"
        case .showPensampel: "Pensampel"
        case .showElektronik: "Elektronik"
        case .showPropulsi: "Propulsi"
        }
    }

    var components: [RoverComponent] {
        switch self {
        case .showAll: RoverComponent.allCases
        case .showPensampel: [.pensampel]
        case .showElektronik: [.antenaGPS, .panelSolar, .kamera360]
        case .showPropulsi: [.pendorong]
        }
    }
}

/// App → model triggers that are not group switches.
enum RoverTrigger: String, Sendable {
    case playSampling
    case scaleReal
    case scaleTabletop
}
