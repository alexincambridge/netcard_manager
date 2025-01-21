#!/bin/bash

# Symbols and decorations
wifi_symbol="📶"

# Function to select the country
select_country() {
    country=$(whiptail --title "$wifi_symbol Select Country" \
        --menu "Choose a country to configure Wi-Fi frequencies:" 15 50 3 \
        "UK" "United Kingdom" \
        "US" "United States" \
        "KR" "South Korea" 3>&1 1>&2 2>&3)

    if [[ $? -eq 0 ]]; then
        sudo iw reg set "$country"
        current_region=$(iw reg get | grep country | head -n 1)
        whiptail --msgbox "$wifi_symbol Region configured:\n\n$current_region" 10 50
    fi
}

# Function to show the current configuration
show_current_config() {
    if [[ -z "$1" ]]; then
        whiptail --msgbox "No network card selected." 10 50
        return
    fi

    config=$(iw dev "$1" info 2>/dev/null)
    region=$(iw reg get | grep country | head -n 1)

    if [[ -z "$config" ]]; then
        whiptail --msgbox "Could not retrieve configuration for $1. Verify that it is active." 10 50
        return
    fi

    whiptail --msgbox "$wifi_symbol Current configuration for $1:\n\n$config\n\nRegion:\n$region" 15 60
}

# Function to select band, channel, and display frequency
select_band_and_channel() {
    band=$(whiptail --title "$wifi_symbol Select Band" \
        --menu "Choose a frequency band:" 15 50 3 \
        "1" "2.4GHz" \
        "2" "5GHz" \
        "3" "6GHz" 3>&1 1>&2 2>&3)

    if [[ $? -eq 0 ]]; then
        case "$band" in
            1)
                channels=(
                    1 2412 "MHz" 2 2417 "MHz" 3 2422 "MHz" 4 2427 "MHz" \
                    5 2432 "MHz" 6 2437 "MHz" 7 2442 "MHz" 8 2447 "MHz" \
                    9 2452 "MHz" 10 2457 "MHz" 11 2462 "MHz" 12 2467 "MHz" \
                    13 2472 "MHz" 14 2484 "MHz"
                )
                frequency_band="2.4GHz"
                ;;
            2)
                channels=(
                    36 5180 "MHz" 40 5200 "MHz" 44 5220 "MHz" 48 5240 "MHz" \
                    149 5745 "MHz" 153 5765 "MHz" 157 5785 "MHz" 161 5805 "MHz" \
                    165 5825 "MHz"
                )
                frequency_band="5GHz"
                ;;
            3)
                channels=(
                    1 5955 "MHz" 5 5975 "MHz" 9 5995 "MHz" 13 6015 "MHz" \
                    17 6035 "MHz" 21 6055 "MHz" 25 6075 "MHz" 29 6095 "MHz"
                )
                frequency_band="6GHz"
                ;;
        esac

        menu_channels=()
        for ((i = 0; i < ${#channels[@]}; i += 3)); do
            menu_channels+=("${channels[i]}" "Channel ${channels[i]} (${channels[i+1]} ${channels[i+2]})")
        done

        selected_channel=$(whiptail --title "$wifi_symbol Select Channel" \
            --menu "Choose a channel for the $frequency_band band:" 20 60 8 \
            "${menu_channels[@]}" 3>&1 1>&2 2>&3)

        if [[ $? -eq 0 ]]; then
            for ((i = 0; i < ${#channels[@]}; i += 3)); do
                if [[ "${channels[i]}" == "$selected_channel" ]]; then
                    selected_frequency="${channels[i+1]} ${channels[i+2]}"
                    break
                fi
            done
            whiptail --msgbox "$wifi_symbol Selection complete:\n\nBand: $frequency_band\nChannel: $selected_channel\nFrequency: $selected_frequency" 10 50
        fi
    fi
}

# Function to change the card's mode
set_card_mode() {
    mode=$(whiptail --title "$wifi_symbol Configure Mode" \
        --menu "Choose the mode for $1:" 15 50 2 \
        "1" "Monitor Mode" \
        "2" "Normal Mode" 3>&1 1>&2 2>&3)

    if [[ $? -eq 0 ]]; then
        if [[ "$mode" == "1" ]]; then
            sudo airmon-ng start "$1"
            whiptail --msgbox "$wifi_symbol The card $1 is now in Monitor Mode." 10 50
        elif [[ "$mode" == "2" ]]; then
            sudo airmon-ng stop "$1"
            whiptail --msgbox "$wifi_symbol The card $1 is now in Normal Mode." 10 50
        fi
    fi
}

# Main Menu
main_menu() {
    while true; do
        choice=$(whiptail --title "$wifi_symbol Network Manager" \
            --menu "Main Menu" 15 60 6 \
            "1" "Select Network Card" \
            "2" "View Current Configuration" \
            "3" "Set Country" \
            "4" "Change Card Mode" \
            "5" "Select Band, Channel, and Frequency" \
            "6" "Exit" 3>&1 1>&2 2>&3)

        case "$choice" in
            1)
                selected_card=$(list_network_cards)
                if [[ -n "$selected_card" ]]; then
                    whiptail --msgbox "$wifi_symbol Selected Card: $selected_card" 10 50
                else
                    whiptail --msgbox "$wifi_symbol No card selected." 10 50
                fi
                ;;
            2)
                show_current_config "$selected_card"
                ;;
            3)
                select_country
                ;;
            4)
                if [[ -n "$selected_card" ]]; then
                    set_card_mode "$selected_card"
                else
                    whiptail --msgbox "$wifi_symbol Please select a network card first." 10 50
                fi
                ;;
            5)
                select_band_and_channel
                ;;
            6)
                break
                ;;
            *)
                whiptail --msgbox "$wifi_symbol Invalid option." 10 50
                ;;
        esac
    done
}

# Function to list network cards
list_network_cards() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -E "wl|en")
    IFS=$'\n'
    options=($interfaces)
    unset IFS

    menu_options=()
    for i in "${!options[@]}"; do
        menu_options+=($((i+1)) "${options[$i]}")
    done

    selected=$(whiptail --title "$wifi_symbol Select Network Card" \
        --menu "Choose your network card:" 15 50 8 "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [[ $? -eq 0 ]]; then
        selected_card="${options[$((selected-1))]}"
        echo "$selected_card"
    else
        echo ""
    fi
}

# Run the main menu
main_menu
