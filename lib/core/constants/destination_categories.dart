class DestinationCategoryOption {
  const DestinationCategoryOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

const destinationCategories = [
  DestinationCategoryOption(value: 'alam', label: 'Alam'),
  DestinationCategoryOption(value: 'pantai', label: 'Pantai'),
  DestinationCategoryOption(value: 'budaya', label: 'Budaya'),
  DestinationCategoryOption(value: 'sejarah', label: 'Sejarah'),
  DestinationCategoryOption(value: 'kuliner', label: 'Kuliner'),
  DestinationCategoryOption(value: 'religi', label: 'Religi'),
  DestinationCategoryOption(value: 'keluarga', label: 'Keluarga'),
  DestinationCategoryOption(value: 'petualangan', label: 'Petualangan'),
  DestinationCategoryOption(value: 'edukasi', label: 'Edukasi'),
  DestinationCategoryOption(value: 'belanja', label: 'Belanja'),
];

String destinationCategoryLabel(String? value) {
  return destinationCategories
      .firstWhere(
        (category) => category.value == value,
        orElse: () => destinationCategories.first,
      )
      .label;
}
