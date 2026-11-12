import SwiftUI

public enum BrainSector: Int, CaseIterable, Identifiable {
    case brainstem = 1
    case hippocampus = 2
    case amygdala = 3
    case occipital = 4
    case prefrontal = 5
    
    public var id: Int { rawValue }
    
    public var name: String {
        switch self {
        case .brainstem: return "BRAINSTEM"
        case .hippocampus: return "HIPPOCAMPUS"
        case .amygdala: return "AMYGDALA"
        case .occipital: return "OCCIPITAL CORTEX"
        case .prefrontal: return "PREFRONTAL CORTEX"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .brainstem: return "Autonomous Vital Signs"
        case .hippocampus: return "Fragmented Memory Vault"
        case .amygdala: return "Emotional Trauma Surge"
        case .occipital: return "Sensory Reconnection"
        case .prefrontal: return "Consciousness Awakening"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .brainstem: return .cyan
        case .hippocampus: return .purple
        case .amygdala: return .red
        case .occipital: return .blue
        case .prefrontal: return .mint
        }
    }
    
    public var icon: String {
        switch self {
        case .brainstem: return "waveform.path.ecg"
        case .hippocampus: return "brain.head.profile"
        case .amygdala: return "flame.fill"
        case .occipital: return "eye.fill"
        case .prefrontal: return "sparkles"
        }
    }
}

public struct GameLevelInfo: Identifiable {
    public var id: Int { number }
    public let number: Int
    public let title: String
    public let subtitle: String
    public let target: Int
    public let description: String
    public let sector: BrainSector
    public let memoryLog: String
    public let color: Color
    public let icon: String
    
    // Some levels disable 2x multipliers to test pure skill and survival
    public var allowsScoreMultiplier: Bool {
        // Milestone / Gateway levels require pure skill
        if [6, 12, 18, 24, 28, 29, 30].contains(number) { return false }
        // Acute panic sector (Amygdala) disables 2x boosters
        if sector == .amygdala { return false }
        return true
    }
    
    public init(
        number: Int,
        title: String,
        subtitle: String,
        target: Int,
        description: String,
        sector: BrainSector,
        memoryLog: String,
        color: Color? = nil,
        icon: String? = nil
    ) {
        self.number = number
        self.title = title
        self.subtitle = subtitle
        self.target = target
        self.description = description
        self.sector = sector
        self.memoryLog = memoryLog
        self.color = color ?? sector.themeColor
        self.icon = icon ?? sector.icon
    }
    
    public static func info(for level: Int) -> GameLevelInfo {
        let sector: BrainSector = {
            switch level {
            case 1...6: return .brainstem
            case 7...12: return .hippocampus
            case 13...18: return .amygdala
            case 19...24: return .occipital
            default: return .prefrontal
            }
        }()
        
        let target = level * 1000
        
        let logs: [Int: (title: String, sub: String, desc: String, log: String)] = [
            1: ("FIRST SPARK", "Rhythm Initiation", "Ignite the dormant pacemaker synapse.", "Patient monitor detects faint sinusoidal pulse. The spark has taken hold."),
            2: ("MEDULLA RUN", "Respiratory Sync", "Weave through reflexive barriers.", "\"Breathe in... hold on... we are not giving up on you.\""),
            3: ("PONS BRIDGE", "Neural Crossing", "Traverse the bridge between motor pathways.", "Motor reflexes flickering. Involuntary finger twitch recorded."),
            4: ("SYNAPSE FLOW", "Current Acceleration", "Maintain continuous flow through narrow axons.", "Electrolyte balance stabilizing. Vagus nerve firing."),
            5: ("CRANIAL VEIL", "Threshold Defense", "Navigate high-frequency barrier arrays.", "\"His pulse is stabilizing! Doctor, look at the monitor!\""),
            6: ("GATEWAY ONE", "Sector Transition", "Survive the autonomic pressure surge.", "Brainstem online. Autonomous breathing restored. Entering deep cognitive sector."),
            
            7: ("CHILDHOOD ECHO", "Memory Fragment #1", "Retrieve nostalgia shards floating in the current.", "\"Do you remember that summer by the lake? You promised you'd build that treehouse.\""),
            8: ("FADING PHOTOS", "Synaptic Decay", "Dodge decaying synaptic debris.", "\"Your sister visited today. She placed her drawing beside your bed.\""),
            9: ("FORGOTTEN SONGS", "Harmonic Axon", "Sync with musical memory resonance.", "Auditory cortex shows faint recognition waves to familiar melody."),
            10: ("THE PROMISE", "Emotional Core", "Collect memory shards under rapid flow.", "\"You promised you'd be there for graduation. Don't leave me alone.\""),
            11: ("TEMPORAL LABYRINTH", "Memory Labyrinth", "Navigate moving memory shards in dense fog.", "Reminiscent EEG spikes recorded. Deep memory retrieval active."),
            12: ("THE ARCHIVE", "Vault Reconnection", "Lock down all memory pathways to prevent amnesia.", "Hippocampus link 100% stabilized. Identity matrices intact."),
            
            13: ("ALARM PROTOCOL", "Fight or Flight", "Overcome rapid fire tachycardia obstacles.", "\"Heart rate spiking to 140! Subject is experiencing acute panic state!\""),
            14: ("FEAR RESPONSE", "Trauma Walls", "Dodge jagged crimson fear barriers.", "Adrenaline rush detected in bloodstream. The mind is fighting back."),
            15: ("ARRHYTHMIA", "Irregular Rhythms", "Survive unpredictable barrier shifts.", "Defibrillator on standby. Keep the signal alive through the turbulence!"),
            16: ("CRIMSON GLITCH", "Phasing Storm", "Phase through phantom glitch barriers.", "\"Hold his hand! Talk to him, let him know he's safe!\""),
            17: ("STORM HORIZON", "Trauma Release", "Channel adrenaline to accelerate flow.", "Cortisol levels peaking then subsiding. Emotional wave breaking."),
            18: ("CALM IN CHAOS", "Emotional Equilibrium", "Balance heart rate back to steady rhythm.", "Amygdala stabilized. Fear response converted into raw survival instinct."),
            
            19: ("FIRST LIGHT", "Photoreceptor Wake", "Pierce through blinding optical signals.", "\"His eyelids are fluttering! He might be seeing light!\""),
            20: ("OPTIC CHIASM", "Bifurcation", "Handle intersecting optical pathways.", "Visual processing centers firing. Shadows and shapes resolving."),
            21: ("CHROMATIC PULSE", "Prismatic Waves", "Weave through spectrum shifting barriers.", "Colors returning to the internal mindscape. Neural spectrum expanding."),
            22: ("VISUAL ECHO", "Sensory Cascade", "Precision evasion in rapid sensory stream.", "Visual cortex synchronizing with auditory input."),
            23: ("DREAMSCAPE", "Lucid Flow", "Ride harmonic frequency waves.", "\"Can you see my hand? Squeeze if you can see me...\""),
            24: ("THE ILLUMINATION", "Sensory Awakening", "Complete the sensory circuit.", "All primary sensory hubs re-established. Motor and sensory links unified."),
            
            25: ("EXECUTIVE SPARK", "Frontal Awakening", "Initiate decision-making neural networks.", "Prefrontal cortex activating. Conscious self-awareness initiating."),
            26: ("WILLPOWER", "Defiance", "Power through ultra-dense neural obstacles.", "\"Fight it! You have so much more to live for!\""),
            27: ("THE INNER MONOLOGUE", "Thought Synthesis", "Form coherent thought chains at high speed.", "Subvocal thoughts firing. \"I... am... here.\""),
            28: ("THRESHOLD OF REALITY", "Pre-Awakening Surge", "Withstand maximum synaptic throughput.", "Vital signs normal. Neurological coma breaking apart."),
            29: ("THE FINAL SYNERGY", "All Sectors Unified", "Master all mechanics across unified brain sectors.", "Full cortex synchronization achieved. Coma depth score 15/15."),
            30: ("THE AWAKENING", "Return to Reality", "Pierce the final barrier and wake up.", "Eyes opening. Neural link fully restored. Welcome back.")
        ]
        
        let details = logs[level] ?? (
            "NEURAL PATHWAY \(level)",
            "Sector Link",
            "Maintain transmission to sustain consciousness.",
            "Vital signs stable. Continuing memory recovery."
        )
        
        return GameLevelInfo(
            number: level,
            title: details.title,
            subtitle: details.sub,
            target: target,
            description: details.desc,
            sector: sector,
            memoryLog: details.log
        )
    }
}
