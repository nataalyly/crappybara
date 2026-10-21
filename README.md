## Developer & Contributions
**nataalyly** (Game Programmer, Game Designer)<br/>
**Akqua** (Game Artist, Game Designer)

## About
Crappybara is a cozy, relaxing companion and management game where players care for their very own capybara. Feed your capybara with delicious treats using intuitive drag-and-drop mechanics, manage its energy levels, unlock cute accessories through the sidebar system, collect rare capybaras via gacha, and customize your cozy space. Built with Godot 4 and optimized for smooth web deployment on Itch.io.

<br>

## Key Features
**Interactive Feeding System**: Feed your capybara by dragging food items (peaches, corn, and watermelon) directly into its mouth. Each bite restores energy and triggers dynamic chew animations and sound effects.

**Accessory & Character Customization**: Personalize your capybaras by equipping unique accessories through dedicated accessory layers, sidebars, and character management screens.

**Gacha & Roster Collection**: Expand your family of capybaras using the gacha system, inspect individual stats via detail popups, and seamlessly swap your active companion.

<br>

## Gameplay
<table>
  <tr>
    <td>
      <img src="Crappybara.gif" width="100%">
    </td>
    <td valign="top">

**Platform:** WebGL (Browser) <br>
**Engine:** Godot <br>
**Language:** GDScript <br>

<br>

[![Play Game](https://img.shields.io/badge/▶_Play_on_itch.io-FF6B35?style=for-the-badge&logoColor=white)](https://nataalyly.itch.io/crappybara)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/nataalyly/crappybara)

  </td>
  </tr>
</table>

---

## Scene Flow
```mermaid
flowchart LR
  hs[Home Screen]
  gacha[Gacha Scene]
  chars[Character List]
  detail[Character Detail Popup]
  sidebar[Accessory Sidebar]
  battle[Battle Scene]

  hs -- "Open Gacha" --> gacha
  hs -- "Open Character List" --> chars
  chars -- "View Details" --> detail
  hs -- "Open Accessories" --> sidebar
  hs -- "Enter Door" --> battle
  gacha -- "Return" --> hs
  chars -- "Select Active" --> hs
  sidebar -- "Close" --> hs
  battle -- "Return to Room" --> hs
```

## Layer / Module Design
```mermaid
---
config:
  theme: neutral
  look: neo
---
graph TD
    subgraph "Core & Singletons"
        GameState[GameState.gd]
        SaveManager[SaveManager.gd]
        AudioManager[AudioManager.gd]
        ButtonFX[ButtonFX.gd]
    end
    
    subgraph "Home & HUD"
        HomeScreen[HomeScreen.gd]
    end
    
    subgraph "Character System"
        CharacterData[CharacterData.gd]
        CharacterCard[CharacterCard.gd]
        CharacterListScreen[CharacterListScreen.gd]
        CharacterDetailPopup[CharacterDetailPopup.gd]
    end
    
    subgraph "Accessory System"
        AccessoryData[AccessoryData.gd]
        AccessoryItemCard[AccessoryItemCard.gd]
        AccessoryLayer[AccessoryLayer.gd]
    end
    
    subgraph "Combat & Gacha"
        BattleScene[BattleScene.gd]
        EnemyData[EnemyData.gd]
        GachaScene[GachaScene.gd]
    end
    
    HomeScreen --> GameState
    HomeScreen --> SaveManager
    HomeScreen --> AudioManager
    HomeScreen --> ButtonFX
    
    HomeScreen --> CharacterListScreen
    CharacterListScreen --> CharacterCard
    CharacterCard --> CharacterDetailPopup
    CharacterCard --> CharacterData
    
    HomeScreen --> AccessoryLayer
    AccessoryLayer --> AccessoryData
    
    HomeScreen --> GachaScene
    HomeScreen --> BattleScene
    BattleScene --> EnemyData
    
    classDef coreStyle fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef homeStyle fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef charStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef accStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef combatStyle fill:#ffebee,stroke:#b71c1c,stroke-width:2px
    
    class GameState,SaveManager,AudioManager,ButtonFX coreStyle
    class HomeScreen homeStyle
    class CharacterData,CharacterCard,CharacterListScreen,CharacterDetailPopup charStyle
    class AccessoryData,AccessoryItemCard,AccessoryLayer accStyle
    class BattleScene,EnemyData,GachaScene combatStyle
```

## Modules and Features
The game architecture is built modularly using Godot 4 GDScript, mapping directly to your project files:
| 📂 Script / Module | 📋 Core Responsibility |
|---------|-------------------|
| `HomeScreen.gd` | Controls main HUD layout, feeding mechanics (drag-and-drop food to mouth), energy updates, blinking intervals, character swap animations, and menu routing. |
| `GameState.gd` | Global manager tracking player currencies (gold, tickets), energy levels, experience points, and active character states. |
| `SaveManager.gd` | Handles persistent cross-session data storage via browser-safe JSON serialization (`FileAccess`) optimized for web/Itch.io deployment. |
| `AudioManager.gd` | Manages background music tracks and sound effects (like bite audio) with global volume and playback control. |
| `ButtonFX.gd` | Provides reusable juice and interactive feedback (such as button bounce effects) across UI elements. |
| `CharacterListScreen.gd` & `CharacterCard.gd` | Manages the roster grid interface, displaying owned capybaras, rarity markers, and selection states. |
| `CharacterDetailPopup.gd` & `CharacterData.gd` | Defines resource structures (`CharacterData`) and popup interfaces (`CharacterDetailPopup`) for inspecting specific character stats and details. |
| `AccessoryLayer.gd`, `AccessoryItemCard.gd`, `AccessoryData.gd` | Handles visual layering of equipped items onto capybaras, accessory sidebar item cards, and accessory resource definitions. |
| `GachaScene.gd` | Manages pulling mechanics, ticket/gold expenditure, and reward distributions to unlock new characters. |
| `BattleScene.gd` & `EnemyData.gd` | Manages combat encounters triggered from the room door, referencing enemy stat configurations (`EnemyData`) and handling stage progression. |

<br>

## Game Flow Chart
```mermaid
---
config:
  theme: redux
  look: neo
---
flowchart TD
  start([Game Launch]) --> loadGame[SaveManager: Load Browser Data]
  loadGame --> mainMenu[HomeScreen Ready]
  
  mainMenu --> userAction{Player Action}
  
  userAction -->|Feed Button| checkFeed{Accessories Active / Swapping?}
  userAction -->|Menu Button| openMenu[Show Menu Popup]
  userAction -->|Door Button| checkEnergy{Can Battle?}
  userAction -->|Accessories Button| openAccessory[Open Accessory Sidebar & Layer]
  
  checkFeed -->|No| spawnFood[Spawn Random Food: Peach, Corn, Watermelon]
  spawnFood --> dragFood{Drag to Mouth Zone}
  
  dragFood -->|Overlapping| eatLoop[Start Eat Timer & Alternate Chew Sprites]
  eatLoop --> addEnergy[Add Energy to GameState & Update Bar]
  
  openMenu --> menuChoice{Select Option}
  menuChoice -->|Gacha| openGacha[Instantiate GachaScene]
  menuChoice -->|Characters| openCharList[Instantiate CharacterListScreen]
  
  openCharList --> inspectChar[Click Card -> CharacterDetailPopup]
  openCharList --> switchChar[Select New Active Character] --> swapAnim[Play Drop-in/Drop-out Swap Animation]
  
  checkEnergy -->|Yes| enterBattle[Change Scene to BattleScene]
  checkEnergy -->|No| showWarning[Show Hungry Warning Toast & Shake Button]
```

<br>

## Event Signal Diagram
```mermaid
classDiagram
    class GameState {
        +int gold
        +int tickets
        +float energy
        +String active_character_id
        +get_active_character()
        +add_energy(amount: float)
        +grant_feed_reward()
    }

    class SaveManager {
        +String SAVE_PATH
        +Dictionary game_data
        +save_game()
        +load_game()
    }

    class HomeScreen {
        +update_currency_display()
        +update_energy_display()
        +update_xp_display()
        +_on_feed_button_pressed()
        +_on_food_gui_input(event)
        +play_character_swap()
    }

    class GachaScene {
        +gold_changed Signal
        +tree_exited Signal
    }

    class CharacterListScreen {
        +tree_exited Signal
    }

    class AccessorySidebar {
        +closing Signal
        +tickets_changed Signal
    }

    class AccessoryLayer {
        +refresh()
    }

    HomeScreen --> GameState : reads/writes data
    SaveManager --> GameState : serializes/deserializes
    HomeScreen --> AccessoryLayer : updates display
    HomeScreen --> GachaScene : instantiates & connects signals
    HomeScreen --> CharacterListScreen : instantiates & connects signals
    HomeScreen --> AccessorySidebar : instantiates & connects signals
    GachaScene --> HomeScreen : triggers currency update
    AccessorySidebar --> HomeScreen : triggers currency update
```

<br>

## Controls
| Input | Action |
|---|---|
| `Left Click` & `Drag` | Drag food items from spawn point |
| `Left Click` (Buttons) | Navigate menus, gacha rolls, and toggle accessories |
| `Left Click` | Attack the enemy on BattleScene |

## Development Duration
~1 month — solo, from initial setup to WebGL deployment on itch.io

## Notes
- Best played on desktop via Google Chrome or Microsoft Edge.
- Found a bug? Feel free to open an issue.

## Credits
Made by [Natnat](https://github.com/nataalyly)
