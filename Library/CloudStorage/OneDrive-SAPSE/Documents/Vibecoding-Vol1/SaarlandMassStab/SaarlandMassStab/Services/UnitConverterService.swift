import Foundation

enum AreaUnit: String, CaseIterable {
    case km2 = "km²"
    case ha = "ha"
    case m2 = "m²"
    case fussballfelder = "Fußballfelder"
    case acres = "Acres"

    func toKm2(_ value: Double) -> Double {
        switch self {
        case .km2:           return value
        case .ha:            return value / 100.0
        case .m2:            return value / 1_000_000.0
        case .fussballfelder: return value * 0.00714
        case .acres:         return value * 0.00404686
        }
    }

    func fromKm2(_ value: Double) -> Double {
        switch self {
        case .km2:           return value
        case .ha:            return value * 100.0
        case .m2:            return value * 1_000_000.0
        case .fussballfelder: return value / 0.00714
        case .acres:         return value / 0.00404686
        }
    }
}

struct UnitConverterService {
    func toKm2(_ value: Double, from unit: AreaUnit) -> Double {
        unit.toKm2(value)
    }

    func fromKm2(_ value: Double, to unit: AreaUnit) -> Double {
        unit.fromKm2(value)
    }
}
