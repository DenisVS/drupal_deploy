<?php

namespace Drupal\sibling_menu_block\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\image\Entity\ImageStyle;


//
/**
 * Provides a 'Simple message' Block.
 *
 * @Block(
 *   id = "sibling_menu_block",
 *   admin_label = @Translation("Sibling menu block"),
 *   category = @Translation("custom block example"),
 * )
 */
class SiblingMenuBlock extends BlockBase {
  /**
   * {@inheritdoc}
   * sort multidimension array
   */
  function cmp($a, $b) {
    return strcmp($a['weight'], $b['weight']);
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $depth = 3;

    /** @var \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $language  current language */
    $language = \Drupal::languageManager()->getCurrentLanguage()->getId();
    /** @var \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $defaultLanguage  default language */
    $defaultLanguage = \Drupal::languageManager()->getDefaultLanguage()->getId();
    $aliasPrefix = "/" . $language;
    if ($language == $defaultLanguage) {
      $aliasPrefix = '';
    }

    //get current tid
    $route = \Drupal::routeMatch();

    /** @var \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $current_tid  id of term  where we are now */
    $current_tid = $route->getRawParameter('taxonomy_term');

    //get aliases
    $aliasManager = \Drupal::service('path_alias.manager');

    //we need to know who is our parent to display link in navigation
    $parent = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadParents($current_tid);
    $parent = reset($parent);
    $myParent['id'] = $parent->id();
    $myParent['uri'] = $aliasPrefix . $aliasManager->getAliasByPath('/taxonomy/term/' . $myParent['id']);
    $oneParent = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->load($myParent['id']);
    $oneParent = $oneParent->hasTranslation($language) ? $oneParent->getTranslation($language) : $oneParent;
    $myParent['name'] = $oneParent->getName();

    // get name from  tid
    /** @var \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $current_term  taxonomy therm where we are now */
    $current_term = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->load($current_tid);
    $current_term = $current_term->hasTranslation($language) ? $current_term->getTranslation($language) : $current_term;
    /** @var \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $current_name  name or page where we are now */
    $current_name = $current_term->getName();
    $root_parents = ["11", "69"];

    // Here we get all parent terms
    $allParents = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadAllParents($current_term->id());
    $allParKeys = array_keys((array) $allParents);
    foreach ($allParKeys as $current_allParents_key) {
      //Now we determine, if tid exist in array. If so, this tid will be in the next function.
      if (in_array(strval($current_allParents_key), $root_parents, TRUE)) {
        $root_tid = $current_allParents_key;
      }
    }

    // Load the taxonomy tree using values.
    /** @var \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $tree  taxonomy therm tree as an object */
    $tree = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadTree(
      'products', // The taxonomy term vocabulary machine name.
      $root_tid,                 // The "tid" of parent using "0" to get all.
      NULL,                 // Get all levels.
      TRUE               // Get little load of taxonomy term entity.
    );




    /** @property \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $wholeMenuData  Formed by us the whole vocabulary with deep, determined loadTree parameters */
    $wholeMenuData = [];

    foreach ($tree as $key => $term) {

      //$term = $term->getTranslation($language);
      $term = $term->hasTranslation($language) ? $term->getTranslation($language) : $term;
      $wholeMenuData[$key]['id'] = $term->id();
      $wholeMenuData[$key]['name'] = $term->getName();
      $wholeMenuData[$key]['description'] = $term->getDescription();
      $wholeMenuData[$key]['weight'] = $term->getWeight();
      // determine parent of term we processing in the cycle
      $parent = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadParents($term->id());
      $parent_key = array_keys($parent);
      $wholeMenuData[$key]['parent'] = reset($parent_key);

      // if current id = processig term id, then let $current_processing_parent will parent of it.
      if ($term->id() == $current_tid) {
        /** @var \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock $current_processing_parent parent of term we processing in the cycle */
        $current_processing_parent = $wholeMenuData[$key]['parent'];
      }

      // Get depth of processing taxonomy term
      /** @property \Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock  $parents array of parents */
      $parents = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->loadAllParents($term->id());
      $wholeMenuData[$key]['depth'] = count($parents);
      $wholeMenuData[$key]['uri'] = $aliasPrefix . $aliasManager->getAliasByPath('/taxonomy/term/' . $wholeMenuData[$key]['id']);
      // get another fields
      foreach ($term->getFields(TRUE) as $field) {
        //get image url
        if ($field->getName() == 'field_products_category_picture') {
          if (isset($field->getValue()[0]['target_id'])) {
            $fid = $field->getValue()[0]['target_id']; // File ID, 
            // Note the [0] in the array. We assume there is always going to be 1 image here. 
            // If your field allows more than 1 image, you will need to loop through each $field->getValue()
            $file = \Drupal\file\Entity\File::load($fid);
            $image_uri = $file->getFileUri();
            $style = ImageStyle::load('thumbnail');
            $file_url = $style->buildUrl($image_uri);
            $wholeMenuData[$key]['image'] = $file_url;
          }
        }

      }
    }

    // is it a top level of settings terms?
    foreach ($wholeMenuData as $key => $field) {
      if ($field['depth'] < $depth) {
        unset($wholeMenuData[$key]);
      }

      if ((isset($current_processing_parent) and $field['parent'] == $current_processing_parent) or $field['parent'] == $current_tid) {

      }
      else {
        unset($wholeMenuData[$key]);

      }
    }

    // If it's me, then exclude me!
    foreach ($wholeMenuData as $key => $field) {
      if ($field['id'] == $current_tid) {
        unset($wholeMenuData[$key]);
      }
    }

    usort($wholeMenuData, array('Drupal\sibling_menu_block\Plugin\Block\SiblingMenuBlock', 'cmp'));
    $output = '<div class="wrapper_siblings">';

    $output .= '<div class="parent-term-link-navigation-container"><div class="parent-term-link-navigation"><a href="' . $myParent['uri'] . '">' . $myParent['name'] . '&nbsp;</a>🡆</div></div>';

    foreach ($wholeMenuData as $field) {
      $output .= '<div class="wrapper_sibling"><div class="sibling-img">
      <a href="' . $field['uri'] . '"><img src="' . $field['image'] . '" height="150" width="150"></a>
      </div>
      <div class="sibliing-info"><div class="sibling-text">
        <H2><a href="' . $field['uri'] . '">' . $field['name'] . '</a></H2>
        <p>' . $field['description'] . '</p>
        </div>
        </div>
        </div>';
    }
    $output .= '<div class="siblings-header-container"><h1  class="siblings-header">' . $current_name . '</h1></div></div>';
    return [
      '#title' => $current_name,
      '#markup' => $this->t($output),
      '#attached' => [
        'library' => [
          'sibling_menu_block/sibling-cards',
        ],
      ],
    ];
  }

  public function getCacheMaxAge() {
    return 0;
  }

}


