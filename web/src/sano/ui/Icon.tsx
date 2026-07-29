import {
  Sun, Sliders, Cross, Book, Leaf, Waves, Droplet, Droplets, Heart, Sparkles,
  Calendar, CalendarCheck, Activity, Wind, Brain, BatteryLow, Footprints, Tornado, Moon,
  Thermometer, Hand, Utensils, Cloud, Zap, Turtle, Circle, Truck, Send, Bell, Pill,
  MessageCircle, ChevronRight, ChevronLeft, ChevronDown, X, Plus, Check, Mic, Square, Volume2,
  VolumeX, Play, Pause, Bookmark, ThumbsUp, ThumbsDown, Lock, ShieldCheck, Info, Phone, MapPin,
  Car, FileText, FolderOpen, Receipt, Stethoscope, Syringe, BookOpen, Image, Apple, Search,
  ArrowUpRight, Paperclip, CornerDownRight, Inbox, Sprout, Dumbbell, ForkKnife, RotateCcw,
  CreditCard, Link2, Map, Camera, Mail, Wallet,
  type LucideIcon,
} from "lucide-react";

const map: Record<string, LucideIcon> = {
  // tabs
  "sun.haze": Sun, "cross.case": Cross, "book.closed": Book, leaf: Leaf, "water.waves": Waves,
  // conditions / symptoms
  droplet: Droplet, droplets: Droplets, heart: Heart, sparkles: Sparkles, calendar: Calendar,
  "calendar-check": CalendarCheck, activity: Activity, wind: Wind, brain: Brain, "battery-low": BatteryLow,
  footprints: Footprints, tornado: Tornado, moon: Moon, thermometer: Thermometer, hand: Hand,
  utensils: Utensils, cloud: Cloud, zap: Zap, turtle: Turtle, circle: Circle,
  // actions
  truck: Truck, send: Send, bell: Bell, pill: Pill, pills: Pill, sprout: Sprout, dumbbell: Dumbbell,
  // ui
  sliders: Sliders, "message-circle": MessageCircle, chevronRight: ChevronRight, chevronLeft: ChevronLeft,
  chevronDown: ChevronDown, x: X, plus: Plus, check: Check, mic: Mic, square: Square, volume: Volume2,
  mute: VolumeX, play: Play, pause: Pause, bookmark: Bookmark, thumbsUp: ThumbsUp, thumbsDown: ThumbsDown,
  lock: Lock, shield: ShieldCheck, info: Info, phone: Phone, mapPin: MapPin, car: Car, file: FileText,
  folder: FolderOpen, receipt: Receipt, stethoscope: Stethoscope, syringe: Syringe, book: BookOpen,
  image: Image, apple: Apple, search: Search, arrowUpRight: ArrowUpRight, paperclip: Paperclip,
  cornerDownRight: CornerDownRight, tray: Inbox, forkKnife: ForkKnife, rotate: RotateCcw,
  creditcard: CreditCard, link: Link2, map: Map, camera: Camera, envelope: Mail, wallet: Wallet,
};

export const Icon: React.FC<{ name: string; size?: number; className?: string; strokeWidth?: number }> = ({
  name, size = 20, className, strokeWidth = 1.9,
}) => {
  const C = map[name] ?? Circle;
  return <C size={size} className={className} strokeWidth={strokeWidth} />;
};
