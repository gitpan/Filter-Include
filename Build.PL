use Module::Build;

Module::Build->new(
  module_name => 'Filter::Include',
  license     => 'perl',

  requires    => {
             'perl'           => '5.6.1',
             'Regexp::Common' => '>= 0.01',
             'Filter::Simple' => '>= 0.70',
  },
)->create_build_script;
