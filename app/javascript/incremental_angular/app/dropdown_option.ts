export interface DropdownOption {
  label: string;
  value: string | null;
}

export interface CategorizedDropdownOption extends DropdownOption {
  category: string | null;
}